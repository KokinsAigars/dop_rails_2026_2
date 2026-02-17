export function ensureElementId(element: HTMLElement, attributeName: string): string {
    const existingId = element.getAttribute(attributeName);
    if (existingId) return existingId;

    const newId = (window.crypto as any).randomUUID?.() || `tmp-${Date.now()}`;
    element.setAttribute(attributeName, newId);
    return newId;
}

