
/**
 * Manages font-theme selection and notifies listeners.
 */
export function dataThemeFontInit () {
    const KEY = 'font';

    // Add/remove options as you like
    type FontChoice = 'system' | 'sans' | 'serif' | 'mono' | 'brand';

    const buttons = document.querySelectorAll<HTMLButtonElement>('.font-switcher [data-font]');

    function isFontChoice(v: string): v is FontChoice {
        return (['system','sans','serif','mono','brand'] as const).includes(v as FontChoice);
    }

    function applyFont(font: string) {
        if (isFontChoice(font)) {
            document.documentElement.setAttribute('data-font', font);
        } else {
            // auto/invalid → fall back to defaults in :root
            document.documentElement.removeAttribute('data-font');
            font = 'system';
        }
        localStorage.setItem(KEY, font);
        updateActiveButton(font);
    }

    function updateActiveButton(font: string) {
        buttons.forEach(btn => {
            btn.classList.toggle('active', (btn.dataset.font ?? '') === font);
        });
    }

    function currentFont(): FontChoice {
        return (localStorage.getItem(KEY) as FontChoice) || 'system';
    }

    // Apply saved font on load
    applyFont(currentFont());

    // Hook up buttons
    buttons.forEach((btn) => {
        btn.addEventListener('click', (e) => {
            const choice = (e.currentTarget as HTMLButtonElement).dataset.font as FontChoice | undefined;
            if (!choice) return;
            applyFont(choice);
            updateActiveButton(choice);
        });
    });
}
