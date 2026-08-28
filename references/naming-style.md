# Naming & Readability (rule prefix: NAME / STYLE)

Source: 11.1 Files, 11.2 Variables, 11.3 Classes, Code Structure & Readability.
Flag a violation only when the diff clearly shows it. Most of these are 🔵 nit or 🟡 should-fix, not blockers.

## Files (NAME-F)
- **NAME-F1** 🔵 File names are PascalCase + `.cs` (`StudentService.cs`). Not `student.cs`, `studentService.cs`, `Student_Service.cs`.
- **NAME-F2** 🔵 Partial/aspect files use dotted PascalCase: `StudentService.Validations.cs`, `StudentService.Validations.Add.cs`. Not `StudentServiceValidations.cs` or `StudentService_Validations.cs`.
- **NAME-F3** 🔴 Every `.cs` file must start with the OSOS copyright header. Flag any new or modified file missing it:
  ```
  // ----------------------------------------------------------------------
  // Copyright (C) 2026, by OSOS. All rights reserved.
  // The information and source code contained herein is the exclusive
  // property of OSOS and may not be disclosed, examined or reproduced
  // in whole or in part without explicit written authorization from OSOS.
  // ----------------------------------------------------------------------
  ```

## Variables (NAME-V)
- **NAME-V1** 🔵 Descriptive, whole-word names. `var student = ...` not `var s` / `var stdnt`. Same for lambda params: `students.Where(student => ...)` not `.Where(s => ...)`.
- **NAME-V2** 🔵 Plurals for collections: `var students = new List<Student>()`, not `studentList`.
- **NAME-V3** 🔵 No type suffixes: `student`, not `studentModel` / `studentObj`.
- **NAME-V4** 🔵 Name reflects a deliberately-default value: `Student noStudent = null;`, `int noChangeCount = 0;`.
- **NAME-V5** 🟡 Use `var` when the RHS type is obvious (`var student = new Student();`); use the explicit type when RHS is a method call whose type isn't obvious (`Student student = GetStudent();`). `var` allowed for anonymous types.
- **NAME-V6** 🔵 Single-property init → assign directly after construction; multi-property → object initializer (see 11.2 §2.1.3).
- **STYLE-V7** 🔵 Break any line > 120 chars, starting at the `=`.
- **STYLE-V8** 🔵 Multi-line declarations get a blank line before & after; consecutive single-line declarations get none.

## Classes & Fields (NAME-C)
- **NAME-C1** 🟡 Models have no `Model` suffix (`class Student`, not `StudentModel`). Services are singular + `Service` (`StudentService`), never `StudentsService`, `StudentBusinessLogic`, or `StudentBL`.
- **NAME-C2** 🟡 Private fields are camelCase **without** a leading underscore: `private readonly string studentName;` — flag `_studentName`.
- **NAME-C3** 🟡 Reference private fields with `this.` in constructors/methods to disambiguate (`this.studentName = studentName;`). Flag `_field = param;`.
- **NAME-C4** 🔵 Prefer named args / matching aliases on construction; avoid positional literals: `new Student(name: "Josh", score: 150)` not `new Student("Josh", 150)`. Avoid target-typed `new (...)` when it hides the type.
- **NAME-C5** 🔵 Object-initializer / constructor arg order must match the class's declared property/parameter order.

## Readability (STYLE)
- **STYLE-1** 🟡 Proper indentation; no multiple statements crammed on one line; no single-line class/if bodies.
- **STYLE-2** 🔵 Self-documenting code over comments. Flag redundant/obvious comments (`// Create student`), commented-out code, and misleading/outdated comments. Comments are for non-obvious *intent* only.
- **STYLE-3** 🟡 Consistent .NET conventions throughout; validation via FluentValidation; organize by feature/layer.
