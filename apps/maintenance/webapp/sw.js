/* Service-worker KILL SWITCH.
 *
 * An earlier version of this service worker precached the app shell and
 * runtime-cached the cross-origin UI5 runtime; on some devices that served a
 * stale/partial UI5 and left the app blank. This replacement unregisters the
 * worker and deletes all caches so the app always loads fresh from the network.
 * index.html no longer registers a service worker.
 */
self.addEventListener("install", function () {
    self.skipWaiting();
});

self.addEventListener("activate", function (event) {
    event.waitUntil((async function () {
        try {
            var keys = await caches.keys();
            await Promise.all(keys.map(function (k) { return caches.delete(k); }));
            await self.registration.unregister();
            var clients = await self.clients.matchAll({ type: "window" });
            clients.forEach(function (c) { c.navigate(c.url); });
        } catch (e) { /* ignore */ }
    })());
});
