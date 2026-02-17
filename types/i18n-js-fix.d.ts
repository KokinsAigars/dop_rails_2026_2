declare module "i18n-js" {
    const I18n: {
        new (translations?: Record<string, any>): {
            translations: Record<string, any>;
            locale: string;
            defaultLocale: string;
            enableFallbacks: boolean;
            t(scope: string, options?: Record<string, any>): string;
            l(value: any, scope: string, options?: Record<string, any>): string;
        };
    };
    export default I18n;
}
