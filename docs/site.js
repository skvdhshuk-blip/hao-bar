(function () {
    var storageKey = "haobar-lang";

    function isChinese(value) {
        return String(value || "").toLowerCase().indexOf("zh") === 0;
    }

    function currentLang() {
        try {
            var stored = localStorage.getItem(storageKey);
            if (stored) return isChinese(stored) ? "zh-Hans" : "en";
        } catch (error) {}
        return isChinese(navigator.language) ? "zh-Hans" : "en";
    }

    function setLang(lang) {
        document.documentElement.lang = lang;
        try {
            localStorage.setItem(storageKey, lang);
        } catch (error) {}
        document.querySelectorAll("[data-lang]").forEach(function (button) {
            button.setAttribute("aria-pressed", String(button.getAttribute("data-lang") === lang));
        });
    }

    setLang(currentLang());

    document.querySelectorAll("[data-lang]").forEach(function (button) {
        button.addEventListener("click", function () {
            setLang(button.getAttribute("data-lang"));
        });
    });

    var menubar = document.querySelector("[data-menubar]");
    var toggle = document.querySelector("[data-menubar-toggle]");
    if (menubar && toggle) {
        toggle.addEventListener("click", function () {
            var tucked = menubar.classList.toggle("is-tucked");
            toggle.setAttribute("aria-pressed", String(tucked));
        });
    }
})();
