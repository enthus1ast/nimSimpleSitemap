generate sitemaps for your website.


```nim
import simpleSitemap, times

  var testUrls: seq[UrlDate] = @[
    ("https://foo1.de", now() + 1.years),
    ("https://foo2.de", now()),
    ("https://foo3.de", now()),
    ("https://foo4.de", now()),
    ("https://foo5.de", now()),
  ]

  ## Add even more test links
  for idx in 1 .. 100_000:
    testUrls.add (fmt"https://forum.nim-lang.org/t/{idx}", now())

  let pages = generateSitemaps(
    testUrls,
    urlsOnRecent = 10,
    maxUrlsPerSitemap = 50_000,
    base = "https://forum.nim-lang.org/"
  )

  ## Write generates:
  #
  # sitemap.xml
  #  That you can reference i your robots.txt like:
  #   Sitemap: https://yourpage/sitemap.xml
  #
  # sitemap_0.xml
  # sitemap_n.xml
  #
  # That contain the actual links, it is splitted based on the "maxUrlsPerSitemap" parameter.
  #
  # sitemap_recent.xml
  # That contains only the recent x entries. Based on the modification date..
  write(pages)
```

You can serve these files directly with your webserver.

Also you can add a `robots.txt` that reference the sitemap.xml like so:

```
Sitemap: https://yourpage/sitemap.xml
```
