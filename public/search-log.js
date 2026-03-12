(function () {
  const API_URL = "https://submit.knxhub.top/api/log_search";

  function sendLog(keyword) {
    if (!keyword || keyword.trim() === "") return;

    fetch(API_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        keyword: keyword.trim(),
        page: window.location.pathname,
        referrer: document.referrer,
        user_agent: navigator.userAgent,
        time: new Date().toISOString(),
      }),
    }).catch(function (err) {
      console.log("log error:", err);
    });
  }

  function doSearch() {
    const input = document.getElementById("search-query");
    if (!input) return;

    const keyword = input.value;
    if (!keyword || keyword.trim() === "") return;

    sendLog(keyword);

    window.location.href = "/search/?q=" + encodeURIComponent(keyword.trim());
  }

  function init() {
    const input = document.getElementById("search-query");
    if (!input) return;

    input.addEventListener("keydown", function (e) {
      if (e.key === "Enter") {
        e.preventDefault();
        doSearch();
      }
    });

    const form = input.closest("form");
    if (form) {
      form.addEventListener("submit", function (e) {
        e.preventDefault();
        doSearch();
      });
    }

    window.doSearch = doSearch;
  }

  document.addEventListener("DOMContentLoaded", init);
})();
