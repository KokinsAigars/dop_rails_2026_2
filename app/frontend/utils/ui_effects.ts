/**
 * Flashes the background color of a target element.
 */
export async function flashBackground(
    element: HTMLElement,
    duration: number = 300,
    color: string = "rgb(219, 248, 213)"
): Promise<string> {
    return new Promise((resolve) => {
        if (!element) return resolve('no-element');

        element.style.backgroundColor = color;
        element.style.transition = `background-color ${duration / 1000}s ease`;

        setTimeout(() => {
            element.style.backgroundColor = "transparent";
            // Optional: clear the style attribute after transition
            setTimeout(() => {
                element.style.removeProperty('background-color');
                resolve('done');
            }, duration);
        }, duration);
    });
}

