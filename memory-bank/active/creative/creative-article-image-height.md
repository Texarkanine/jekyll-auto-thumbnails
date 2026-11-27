# Decision: How to keep width and height without locking the height

## Context

What to decide: the mechanism that keeps the served file's `width` and `height` on an article image, and stops those attributes from stretching the picture when the column is narrower than the width.

Why it matters: the attributes are what stop the heading jump. They are also a fixed CSS height. A theme that only sets `max-width: 100%` then paints a narrower width and the full height. The blog is that theme. Other sites set height on purpose (a card, a crop, a gallery thumb). The mechanism has to fix the first group and leave the second group alone.

Constraints:

- Keep both attributes. Dropping the height brings the heading jump back.
- The blog's `max_width` and its theme CSS stay as they are. No edit required there.
- A stylesheet or inline style that sets `height` still wins.
- Images outside `article` stay untouched.
- A page with nothing to rewrite stays the same object. No parse, no new style tag.
- Do not set `object-fit`. A square thumb that sets CSS width and height and relies on the default fill would turn into a letterbox.

## Options Evaluated

- **Zero-specificity rule**: when a page is already being rewritten, prepend `<style>:where(article img){height:auto}</style>` to `head`.
- **Inline style**: set `style="height:auto"` on each article image whose width and height we write.
- **Element rule**: the same head injection, but `article img{height:auto}` with normal specificity.
- **Docs only**: tell the theme to add `height: auto`. No gem output change.

## Analysis

| Criterion | :where rule | Inline style | article img rule | Docs only |
| --- | --- | --- | --- | --- |
| Blog keeps its config and theme, and the picture keeps its shape | Yes | Yes | Yes | No |
| `img { height: ... }` and class heights still win | Yes | No | Class wins, `img` loses | Yes |
| Attributes stay, so the ratio stays reserved | Yes | Yes | Yes | Yes |
| Header and sidebar images stay as they are | Yes | Yes | Yes | Yes |
| Unchanged pages stay byte-identical | Yes | Yes | Yes | Yes |
| Survives a stylesheet that forbids inline style | No | No | No | Yes |

Key insights:

- The width and height attributes have two jobs. They reserve the ratio, and they act as CSS `width` and `height` at specificity zero. `height: auto` turns off the second job for height. The ratio mapping stays, so a shrunk width still gets the matching height, including before the file loads.
- Inline style fixes the blog and overrides every stylesheet height on the images we touch. Card crops and gallery thumbs that set height from a class would break. That is a smaller safe slice.
- `article img { height: auto }` beats a theme's `img { height: ... }`. `:where()` does not. The cost of `:where()` is browsers that ignore it. In those browsers the rule is dropped and the page looks as it does today. Those same browsers do not do the modern ratio reservation either.
- `object-fit: contain` would hide a stretch when both `max-width` and `max-height` bind. It would also letterbox thumbs that set a CSS box and expect the default fill. Leave `object-fit` to the author.
- The rule has to be injected only when the rewrite already changes the page. Injecting it on a clean page would serialize pages the plugin promised to leave untouched, and the HTML4 parser would add its extra content-type meta.

Shapes the rule covers, with no site edit:

- Article image, no attributes, or width only. The gem writes both numbers. The theme has `max-width: 100%` or `width: 100%` and no height. The column may shrink. This is the blog, including the saucer and the X-wing.
- The theme already has `height: auto` (Bootstrap, a polaroid). The new rule is redundant. The picture is unchanged.
- The layout never shrinks the image. The width hint is still the file width, and `height: auto` computes the same pixel height. The picture is unchanged.
- A class or an element rule sets `height`, including `height: auto`. That rule wins. Polaroid cards stay on their own rule.
- An article image with no attributes, on a page rewritten for a different image. `height: auto` is already the initial value. No change.
- A small article image, such as an 88 by 31 button. It stays that size until the column is narrower than 88px, then it scales in ratio instead of stretching.

Shapes we leave alone on purpose, and what the author does:

- **A CSS `height` other than the one we set.** A class, `img { height: ... }`, `article img { height: ... }`, or an inline style wins. If that height is a fixed length and the width also shrinks, the picture can still stretch. Set `height: auto`, or set `object-fit: contain` or `cover` when the box is capped on both axes.
- **`max-width` and `max-height` both bind.** `height: auto` sizes from the ratio, then `max-height` caps the box, and the default `object-fit` is fill, so the bitmap can still stretch. Add `object-fit: contain` or `cover`. The gem does not set `object-fit`.
- **Both attributes already match the file, and the src does not change.** The page is not rewritten, so no style tag is added. This stretch predates the height-writing change. Add `:where(article img){height:auto}` to the site stylesheet.
- **A policy that blocks inline `<style>`.** The tag is ignored. Add the same rule to a stylesheet the policy allows.
- **A browser that does not understand `:where()`.** The rule is ignored. The page keeps today's behavior.
- **Images outside `article`.** Not our images. A header logo with both attributes can still stretch under `max-width: 100%`.
- **A mismatched width and height used as a stretch, on a page we do rewrite.** The picture keeps the file's ratio. To stretch or crop, set the box in CSS and set `object-fit`.
- **Something after this plugin strips `<style>`.** The attributes remain and the height locks again. Put the rule in the site stylesheet.
- **A `<picture>` or `srcset` whose selected file has a different ratio than the attributes.** Pre-existing. The attributes describe the `src` we measured. This rule does not pick a source.

## Decision

**Selected**: Zero-specificity rule
**Rationale**: It fixes the blog and every other article page we rewrite whose stylesheet shrinks the width and does not set a height. It loses to any real height selector, so cards, crops, and gallery thumbs keep their CSS. Inline style and a normal `article img` rule both fix the blog by overriding styles people actually set.
**Tradeoff**: The rule is an inline style tag, so a style policy or a later sanitizer can drop it, and browsers that ignore `:where()` do not get it. Pages we do not rewrite do not get it. Both axes capped, and a deliberate attribute stretch, stay the author's CSS.

## Implementation Notes

- In `Hooks.replace_urls`, when the document is already modified, prepend one `<style>:where(article img){height:auto}</style>` to `head`. Do not add a second copy.
- Do not add it when the method returns the input object.
- Keep writing both attributes.
- Tests: attributes remain, the rule is the first `head style`, an author `article img { height }` rule remains after it, a second copy is not added, an unchanged page stays the same object, a non-article image gains neither attributes nor the rule.
- README: state the rule, and list the shapes above with what the author adds.
