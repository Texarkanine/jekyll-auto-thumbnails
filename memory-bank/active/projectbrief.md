# Project Brief

## User Story

As a reader of a Jekyll site, I want a link to a heading to land on that heading and stay there, so that images further up the page do not push the heading off the screen when they load.

## Use-Case(s)

### Use-Case 1

A page contains local images inside `<article>`. The reader follows a link to a heading further down the page before those images have a layout height. The browser scrolls to where the heading is now. The images then load and grow, and the heading moves.

### Use-Case 2

An author asks for a thumbnail with only `width`, only `height`, or with no size plus an `auto_thumbnails.max_width` or `max_height` limit. The published image tag still carries both numbers, and those numbers match the file the browser loads.

## Requirements

Implement [issue 70](https://github.com/Texarkanine/jekyll-auto-thumbnails/issues/70) as written.

1. When the scanner has measured a local image inside `<article>`, write both `width` and `height` on that tag.
2. Write the size of the file the browser will load. When `src` points at a thumbnail, write the thumbnail width and the thumbnail height. Do not write the size of the original file.
3. Do this when `src` changes to a thumbnail. Also do this when the plugin measured the image and did not make a thumbnail.
4. Cover the four current gaps: a tag with only `width` or only `height`; a tag with no size whose image exceeds `max_width` or `max_height`; a tag with no size whose image is within the limit; and a measured image the plugin skips because the calculated size matches the original file.
5. Posts and other collection documents go through the same code. The plugin reads `site.documents` and `site.pages`.

## Constraints

1. Do not change an image outside `<article>`.
2. Do not change a remote image that this plugin does not read.
3. Authors may still request a thumbnail with only a width, only a height, or with no size plus a max-width or max-height limit. Those two numbers on the finished tag are the aspect ratio of the file the browser loads. CSS still sets the width the reader sees.
4. The HTML rule is [maps to the aspect-ratio property](https://html.spec.whatwg.org/multipage/rendering.html#maps-to-the-aspect-ratio-property). The shorter form is [images without dimensions](https://web.dev/articles/optimize-cls#images-without-dimensions).

## Acceptance Criteria

1. A measured local image inside `<article>` has both `width` and `height` in the published HTML, including when the plugin does not change `src`.
2. When `src` points at a thumbnail, `width` and `height` match that thumbnail, not the original file.
3. An image outside `<article>`, and a remote image this plugin does not read, are unchanged.
