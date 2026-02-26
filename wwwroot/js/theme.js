window.themeManager = {
    get: function () {
        return localStorage.getItem('nw-theme') || 'light';
    },
    set: function (theme) {
        localStorage.setItem('nw-theme', theme);
        document.documentElement.setAttribute('data-theme', theme);
    },
    init: function () {
        var theme = localStorage.getItem('nw-theme') || 'light';
        document.documentElement.setAttribute('data-theme', theme);
    }
};
// Apply immediately on load
window.themeManager.init();
