declare module "i18n-js" {
    // Default export is a constructable class with instance props:
    export default class I18n {
        constructor(translations?: Record<string, any>);

        // instance members
        translations: Record<string, any>;
        locale: string;
        defaultLocale: string;
        enableFallbacks: boolean;
        t(scope: string, options?: Record<string, any>): string;
        l(value: any, scope: string, options?: Record<string, any>): string;

        // keep static members too (optional)
        static translations: Record<string, any>;
        static locale: string;
        static defaultLocale: string;
        static enableFallbacks: boolean;
        static t(scope: string, options?: Record<string, any>): string;
        static l(value: any, scope: string, options?: Record<string, any>): string;
    }
}