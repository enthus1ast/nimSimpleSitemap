import std/xmltree, times, uri, math, strformat, sequtils, os, algorithm
# import print

type
  UrlDate = tuple[url: string, dateChanged: Datetime]


func genLastModElem(dateChanged: Datetime): XmlNode =
    result = newElement("lastmod")
    # result.add newText(dateChanged.format("YYYY-MM-dd"))
    result.add newText($dateChanged)

proc generateUrlset*(urls: seq[UrlDate]): XmlNode =
  var elemUrlset = newElement("urlset")
  elemUrlset.attrs = {
    "xmlns": "http://www.sitemaps.org/schemas/sitemap/0.9",
    "xmlns:image": "http://www.google.com/schemas/sitemap-image/1.1",
    "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance",
    "xsi:schemaLocation": "http://www.sitemaps.org/schemas/sitemap/0.9 http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd http://www.google.com/schemas/sitemap-image/1.1 http://www.google.com/schemas/sitemap-image/1.1/sitemap-image.xsd"
  }.toXmlAttributes()
  for (url, dateChanged) in urls:
    var elemUrl = newElement("url")
    var loc = newElement("loc")
    loc.add newText(url)
    elemUrl.add(loc)

    var elemLastMod = genLastModElem(dateChanged)
    elemUrl.add elemLastMod
    elemUrlset.add elemUrl

  return elemUrlset


proc getMostRecentChange(urls: seq[UrlDate]): Datetime =
  result = urls[0].dateChanged
  for (url, dateChanged) in urls:
    if dateChanged > result:
      result = dateChanged

type
  Page = tuple[filename: string, content: XmlNode]

proc cmpUrlDate(x, y: UrlDate): int =
  cmp(x.dateChanged, y.dateChanged)

proc generateSitemaps*(urls: seq[UrlDate], urlsOnRecent = 10, maxUrlsPerSitemap = 50_000, base = "https://forum.nim-lang.org/"): seq[Page] =
  ## Generates sitemaps
  var baseUri = parseUri(base)
  var elemSitemapindex = newElement("sitemapindex")
  elemSitemapindex.attrs = {"xmlns": "http://www.sitemaps.org/schemas/sitemap/0.9"}.toXmlAttributes()

  # print min(urls.len, urlsOnRecent)
  # var recent = urls[0 ..< min(urls.len, urlsOnRecent)]
  let urlsSorted = sorted(urls, cmpUrlDate, SortOrder.Ascending)
  var recent = urlsSorted[^min(urls.len, urlsOnRecent) .. ^1]
  var elemSitemapRecent = newElement("sitemap")
  var elemSitemapRecentLoc = newElement("loc")
  elemSitemapRecentLoc.add newText($(baseUri / "sitemap_recent.xml"))
  elemSitemapRecent.add elemSitemapRecentLoc

  var elemSitemapRecentLastMod = genLastModElem(getMostRecentChange(recent))
  elemSitemapRecent.add elemSitemapRecentLastMod
  elemSitemapindex.add elemSitemapRecent

  var sitemapRecent = generateUrlset(recent)
  result.add ("sitemap_recent.xml", sitemapRecent)

  # print urls.len, maxUrlsPerSitemap, urls.len / maxUrlsPerSitemap, (urls.len / maxUrlsPerSitemap).ceil
  let howManySitemaps = (urls.len / maxUrlsPerSitemap).ceil.int
  for idx, distUrls in urls.distribute(howManySitemaps, spread = false).pairs:
    var elemSitemap = newElement("sitemap")
    var elemSitemapLoc = newElement("loc")
    elemSitemapLoc.add newText($(baseUri / fmt"sitemap_{idx}.xml"))
    elemSitemap.add elemSitemapLoc

    var elemSitemapLastMod = genLastModElem(getMostRecentChange(recent))
    elemSitemap.add elemSitemapLastMod

    elemSitemapindex.add elemSitemap

    result.add (fmt"sitemap_{idx}.xml", generateUrlset(distUrls))

  result.add ("sitemap.xml", elemSitemapindex)

proc write(pages: seq[Page], folder = getAppDir() / "sitemaps") =
  if not dirExists(folder):
    createDir(folder)
  for (filename, data) in pages:
    writeFile(folder / filename, $data)

when isMainModule:
  var testUrls: seq[UrlDate] = @[
    ("https://foo1.de", now() + 1.years),
  #   ("https://foo2.de", now()),
  #   ("https://foo3.de", now()),
  #   ("https://foo4.de", now()),
  #   ("https://foo5.de", now()),
  ]
  for idx in 1 .. 100_000:
    testUrls.add (fmt"https://forum.nim-lang.org/t/{idx}", now())
  let pages = generateSitemaps(testUrls)
  # echo pages
  write(pages)

