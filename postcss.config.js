export default {
    map: true,
    plugins: {
        autoprefixer: {},
        ...(process.env.NODE_ENV === "production" ? { cssnano: { preset: "default" } } : {}),
    },
};

// export default {
//     plugins: {
//         autoprefixer: {},
//         cssnano: { preset: "default" },
//     },
// };
