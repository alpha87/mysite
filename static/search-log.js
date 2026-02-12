(function () {
  function sendLog(keyword) {
    if (!keyword || keyword.trim() === "") return;

    fetch("/api/log_search", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        keyword: keyword.trim(),
        page: window.location.pathname,
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

    // 跳转到原搜索页
    window.location.href = "/search/?q=" + encodeURIComponent(keyword.trim());
  }

  function init() {
    const input = document.getElementById("search-query");
    if (!input) return;

    // 监听回车键
    input.addEventListener("keydown", function (e) {
      if (e.key === "Enter") {
        e.preventDefault();
        doSearch();
      }
    });

    // 如果页面有 form，防止默认提交
    const form = input.closest("form");
    if (form) {
      form.addEventListener("submit", function (e) {
        e.preventDefault();
        doSearch();
      });
    }

    // 暴露全局函数（防止主题内部调用）
    window.doSearch = doSearch;
  }

  document.addEventListener("DOMContentLoaded", init);
})();
