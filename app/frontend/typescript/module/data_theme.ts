
/**
 * Manages theme selection and notifies listeners.
 */
export function dataThemeColorInit () {
    const KEY = 'theme';

    type ThemeChoice = 'light' | 'dark' | 'terra' | 'companyA';

    const buttons = document.querySelectorAll<HTMLButtonElement>(".theme-switcher [data-theme]");

    function applyTheme(theme: string) {
        if (theme === 'light' || theme === 'dark' || theme === 'terra' || theme === 'companyA') {
            document.documentElement.setAttribute('data-theme', theme);
        } else {
            // auto → let prefers-color-scheme decide
            document.documentElement.removeAttribute('data-theme');
        }
        localStorage.setItem(KEY, theme);
        updateActiveButton(theme);
    }

    function updateActiveButton(theme: string) {
        buttons.forEach(btn => {
            btn.classList.toggle('active', (btn.dataset.theme ?? '') === theme);
        });
    }

    function currentTheme() {
        return localStorage.getItem(KEY) || 'light';
    }


    // Apply saved theme on load
    applyTheme(currentTheme());


    // Hook up buttons => addEventListener on them to call function on changing theme
    buttons.forEach((btn) => {
        //console.log(btn);
        btn.addEventListener('click', (e) => {
            const choice = (e.currentTarget as HTMLButtonElement).dataset.theme as ThemeChoice;
            if (!choice) return;               // guard (TS: string | undefined)
            applyTheme(choice);
            updateActiveButton(choice);
        });
    });

}


