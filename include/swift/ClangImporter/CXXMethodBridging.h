#ifndef SWIFT_CXXMETHODBRIDGING_H
#define SWIFT_CXXMETHODBRIDGING_H

#include "swift/AST/Decl.h"
#include "clang/AST/DeclCXX.h"
#include "llvm/ADT/StringRef.h"

#include <string>
namespace swift {
struct CXXMethodBridging {
  enum class Kind { unkown, getter, setter, subscript };

  enum class NameKind { unkown, snake, lower, camel, title };

  CXXMethodBridging(const clang::CXXMethodDecl *method) : method(method) {}

  Kind classify() {
    if (nameIsBlacklist())
      return Kind::unkown;

    // this should be handled as snake case. See: rdar://89453010
    // case. In the future we could
    //  import these too, though.
    auto nameKind = classifyNameKind();
    if (nameKind != NameKind::title && nameKind != NameKind::camel &&
        nameKind != NameKind::lower)
      return Kind::unkown;

    if (getClangName().startswith_insensitive("set")) {
      // Setters only have one parameter.
      if (method->getNumParams() != 1)
        return Kind::unkown;

      // rdar://89453106 (We need to handle imported properties that return a
      // reference)
      if (method->getParamDecl(0)->getType()->isReferenceType())
        return Kind::unkown;

      return Kind::setter;
    }

    // Getters and subscripts cannot return void.
    if (method->getReturnType()->isVoidType())
      return Kind::unkown;

    if (getClangName().startswith_insensitive("get")) {
      // Getters cannot take arguments.
      if (method->getNumParams() != 0)
        return Kind::unkown;

      // rdar://89453106 (We need to handle imported properties that return a
      // reference)
      if (method->getReturnType()->isReferenceType())
        return Kind::unkown;

      return Kind::getter;
    }

    // rdar://89453187 (Add subscripts clarification to CXXMethod Bridging to
    // clean up importDecl)
    return Kind::unkown;
  }

  NameKind classifyNameKind() {
    bool allLower = llvm::all_of(getClangName(), islower);

    if (getClangName().empty())
      return NameKind::unkown;

    if (getClangName().contains('_'))
      return allLower ? NameKind::snake : NameKind::unkown;

    if (allLower)
      return NameKind::lower;

    return islower(getClangName().front()) ? NameKind::camel : NameKind::title;
  }

  llvm::StringRef getClangName() {
    if (!method->getDeclName().isIdentifier())
      return "";

    return method->getName();
  }

  // this should be handled as snake case. See: rdar://89453010
  std::string importNameAsCamelCaseName() {
    std::string output;
    auto kind = classify();
    if (kind == Kind::getter || kind == Kind::setter) {
      output = getClangName().drop_front(3).str();
    } else {
      output = getClangName().str();
    }

    if (output.empty())
      return output;

    // No work to do.
    if (classifyNameKind() == NameKind::lower)
      return output;

    // The first character is always lowercase.
    output.front() = std::tolower(output.front());

    // We already lowercased the first element, so start at one. Look at the
    // current element and the next one. To handle cases like UTF8String, start
    // making all the uppercase characters lower, until we see an upper case
    // character followed by a lower case character (i.e., "St").
    for (size_t i = 1; i < output.size(); i++) {
      size_t next = i + 1;

      // If we see two upper case characters (or an upper case character and a
      // number) make the current character lower case.
      if (std::isupper(output[i]) &&
          (std::isupper(output[next]) || std::isdigit(output[next]))) {
        output[i] = std::tolower(output[i]);
        // If we found an upper case character followed by a lower case
        // character, we went far enough. We're done.
      } else if (std::isupper(output[i]) && std::islower(output[next])) {
        break;
        // If we got to the end of the string, we're done.
      } else if (std::isupper(output[i]) && next + 1 > output.size()) {
        output[i] = std::tolower(output[i]);
        break;
      }
    }

    return output;
  }

  std::string importNameAsTitleCaseName() {
    auto output = importNameAsCamelCaseName();
    output.front() = std::toupper(output.front());
    return output;
  }

private:
  const clang::CXXMethodDecl *method = nullptr;

  bool nameIsBlacklist() {
    auto loweredName = getClangName().lower();
    // Names that start with "get" or "set" but aren't getters or setters.
    return loweredName == "getter" || loweredName == "setter" ||
           loweredName == "get" || loweredName == "set";
  }
};
} // namespace swift
#endif // SWIFT_CXXMETHODBRIDGING_H
