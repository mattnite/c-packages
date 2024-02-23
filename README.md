# c-packages: A Collection of C projects wrapped in the Zig build system

## Package List

To see the list of libraries, go checkout the `projects/` directory or the
latest release.

## Motivations

Over the years I've made `build.zig` wrappers for C/C++ libraries and with the
Zig project changes I either have to keep a ton of these wrappers up-to-date,
which is a lot of overhead on my open source time, or they end up bit-rotting.
Usually it's the latter. This repo is a single place to manage all of these
projects, so when breaks do happen upstream, I can blitz through a single
codebase.

I've also created a [tool](https://github.com/mattnite/boxzer) to help create
tarballs for all these packages. If a project depends on another, you can
annotate that using a `path` dependency in the `build.zig.zon`. When a release
is cut, `boxzer` will reroute these dependencies to the correct URL. Each
library is uploaded as a separate tarball, so you don't download all packages
when you depend on any of these.

## Contributions

If you want to add your wrapped C/C++ library to this project, either to
increase the chances of others reusing your work, or to pool effort to maintain
these "build scripts" by all means please make that PR.

## Conventions

- A C/C++ project goes under the `projects/` directory with just its name
- A project directory will contain:
  - The original project as a submodule named `c`
  - Any Zig bindings will go under a `zig` directory, with the root name of the
    module being `bindings.zig`, unless it makes sense to do otherwise.
  - A LICENSE for the `build.zig` and bindings code, usually MIT.
  - For the `build.zig.zon`:
    - The version will be the version of the project, not the packaging code.
    - Dependencies on other projects are conveyed using `path`
  - The `build.zig` must export:
    - A `targets` declaration, when running `zig build` at the root, this will
      compile all projects in all their advertised targets.
    - A `test` step, when running `zig build` at the root, this will run all
      tests for all projects in all build modes for the native machine. The step
      does not necessarily need to depend on anything. Conditional logic will be
      needed if the project is only supported on particular targets.

## What about multiple versions of a library?

This usecase isn't built into the project right now. I see this project first as
a way to make my life easier, if it does start to gain traction I'll come up
with a way to cover this. Until then consider this as a curated list of C/C++
packages for the Zig ecosystem rather than a fully fledged packaging solution.
