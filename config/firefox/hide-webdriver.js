// hides navigator.webdriver before page scripts run.
const page = `(() => {
  const d = Object.getOwnPropertyDescriptor(Navigator.prototype, "webdriver");
  if (!d || !d.get) return;
  Object.defineProperty(Navigator.prototype, "webdriver", {
    ...d,
    get: new Proxy(d.get, { apply: () => false }),
  });
})();`;

Services.obs.addObserver(
  {
    observe(win) {
      try {
        const sb = Cu.Sandbox(win, { sandboxPrototype: win, wantXrays: false });
        Cu.evalInSandbox(page, sb);
      } catch (e) {
        Cu.reportError("hide-webdriver: " + e);
      }
    },
  },
  "content-document-global-created"
);
