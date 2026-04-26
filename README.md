# @tsonic/aspnetcore

TypeScript declarations and CLR binding metadata for `Microsoft.AspNetCore.App` on .NET 10.

`@tsonic/aspnetcore` is a generated binding package. It exposes ASP.NET Core
namespace modules to Tsonic while the compiled program references the real
ASP.NET Core shared framework.

## Install

```bash
npm install @tsonic/aspnetcore @tsonic/dotnet @tsonic/core
```

The package peers against the matching .NET-major `@tsonic/dotnet`,
`@tsonic/core`, and `@tsonic/microsoft-extensions` packages.

## Use with Tsonic

Add the framework reference and bind it to this type package:

```bash
tsonic add framework Microsoft.AspNetCore.App @tsonic/aspnetcore
tsonic restore
```

This records the shared-framework reference in `tsonic.workspace.json` and
uses the published binding package for TypeScript and compiler metadata.

## Imports

Import ASP.NET Core namespaces through explicit ESM subpaths:

```ts
import { WebApplication } from "@tsonic/aspnetcore/Microsoft.AspNetCore.Builder.js";
import { HttpContext } from "@tsonic/aspnetcore/Microsoft.AspNetCore.Http.js";
```

## Minimal API example

```ts
import { WebApplication } from "@tsonic/aspnetcore/Microsoft.AspNetCore.Builder.js";
import type { ExtensionMethods } from "@tsonic/aspnetcore/Microsoft.AspNetCore.Builder.js";

export function main(): void {
  const builder = WebApplication.CreateBuilder();
  const app = builder.Build() as ExtensionMethods<WebApplication>;

  app.MapGet("/", () => "hello");
  app.Run("http://localhost:8080");
}
```

## Package shape

The package contains generated namespace facades, ESM stubs, and `bindings.json`
files:

```text
@tsonic/aspnetcore/
  Microsoft.AspNetCore.Builder.d.ts
  Microsoft.AspNetCore.Builder.js
  Microsoft.AspNetCore.Builder/
    bindings.json
    internal/index.d.ts
  __internal/extensions/index.d.ts
  families.json
```

`bindings.json` is compiler metadata, not user-authored configuration. It
preserves CLR identity, overload families, receiver style, extension methods,
generic constraints, and nullable semantics for Tsonic.

## Versioning

This repo is versioned by .NET major:

- .NET 10 → npm: `@tsonic/aspnetcore@10.x`

## Development

Regenerate from sibling checkouts:

```bash
npm install
./__build/scripts/generate.sh
```

The generation script requires:

- .NET 10 SDK/runtime
- `../tsbindgen`
- `../dotnet`
- `../microsoft-extensions`

For a system .NET install, set `DOTNET_HOME` and `DOTNET_VERSION`:

```bash
DOTNET_HOME=/usr/lib/dotnet DOTNET_VERSION=10.0.5 ./__build/scripts/generate.sh
```

## License

MIT
