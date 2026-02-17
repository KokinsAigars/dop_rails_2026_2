/**
 * What Can Web Workers Do?
 *
 * Heavy computations (e.g., math, image processing, parsing)
 * Background fetching / polling
 * Handling data transformations (e.g., JSON, CSV, audio/video streams)
 * Offloading third-party libraries (e.g., PDF.js, FFmpeg, ML models)
 */

self.onmessage = (event) => {
    const imageData = event.data;
    const data = imageData.data;

    // Convert to grayscale
    for (let i = 0; i < data.length; i += 4) {
        const avg = (data[i] + data[i + 1] + data[i + 2]) / 3;
        data[i]     = avg; // red
        data[i + 1] = avg; // green
        data[i + 2] = avg; // blue
        // data[i + 3] = alpha (leave it)
    }

    // Send back the processed data
    self.postMessage(imageData, [imageData.data.buffer]);
};