# Gatrons Gacha V2 UI

Frontend source for `gatrons-gachav2`.

Stack:

- React
- TypeScript
- Vite
- Tailwind CSS v3
- Motion
- Quantico
- Bun

## Development

```bash
bun install
bun run dev
```

## Production

```bash
bun run build
```

Output:

```text
ui/dist/
```

The FiveM resource loads:

```text
ui/dist/index.html
```

## Vehicle images

For UI source development, place local vehicle images in:

```text
ui/public/vehicles/
```

Example:

```text
ui/public/vehicles/sultanrs.webp
```

Then configure:

```lua
gambar = 'vehicles/sultanrs.webp'
```

and rebuild the frontend.

See the root `README.md` for full installation and resource documentation.
