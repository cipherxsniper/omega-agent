"""
Real web search backed by DuckDuckGo's HTML endpoint (no API key required).
Google's search results page blocks direct scraping, which is why any
web_fetch(google.com/search?q=...) call fails every time.
"""
import re
import html
import urllib.parse
import requests

DDG_HTML_URL = "https://html.duckduckgo.com/html/"

def web_search(query: str, num_results: int = 5):
    """Returns a list of {title, url, snippet} dicts for the query."""
    resp = requests.post(
        DDG_HTML_URL,
        data={"q": query},
        headers={"User-Agent": "Mozilla/5.0 (OmegaAgent)"},
        timeout=15,
    )
    resp.raise_for_status()
    body = resp.text

    results = []
    for m in re.finditer(
        r'<a rel="nofollow" class="result__a" href="(.*?)">(.*?)</a>.*?'
        r'class="result__snippet">(.*?)</a>',
        body,
        re.DOTALL,
    ):
        raw_url, raw_title, raw_snippet = m.groups()
        url = urllib.parse.unquote(raw_url.split("uddg=")[-1].split("&")[0])
        title = html.unescape(re.sub("<.*?>", "", raw_title)).strip()
        snippet = html.unescape(re.sub("<.*?>", "", raw_snippet)).strip()
        results.append({"title": title, "url": url, "snippet": snippet})
        if len(results) >= num_results:
            break
    return results
