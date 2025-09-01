# Assets Directory

This directory contains static assets for the project.

## Supported File Types

- **Images**: PNG, JPG, GIF, SVG, WebP
- **Fonts**: TTF, OTF, WOFF, WOFF2
- **Stylesheets**: CSS, SCSS, LESS
- **JavaScript**: JS, minified versions
- **Media**: MP3, MP4, WebM
- **Documents**: PDF, DOC, DOCX
- **Icons**: ICO, ICNS

## Organization

```
assets/
├── images/
│   ├── logos/
│   ├── icons/
│   └── backgrounds/
├── fonts/
├── styles/
├── scripts/
└── media/
```

## Best Practices

1. **Optimize Images**: Compress images for web use
2. **Use Appropriate Formats**: Choose formats based on use case
3. **Version Assets**: Include version numbers in filenames for cache busting
4. **Organize Logically**: Group related assets in subdirectories
5. **Document Assets**: Keep track of asset sources and licenses

## Examples

- Logo files: `logo-v1.0.png`, `logo-dark.png`
- Icons: `icon-menu.svg`, `icon-close.png`
- Fonts: `font-primary.woff2`, `font-secondary.ttf`

## Notes

- Large assets should be considered for CDN hosting
- Always check file sizes and loading times
- Maintain backup copies of original assets
