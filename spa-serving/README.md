# SPA Serving

Web Applications or Single Page Applications (SPA) use standard Web
browser file formats, such as HTML and JavaScript, to launch a
JavaScript based application in the browser. The HTML _bootstrap
document_ is usually very simple: It barely contains more than what
is needed to load a couple of `.js` and `.css` files.

After our users have loaded the bootstrap document and the Web
Application was initialized, further user interaction (such as
clicking a button) will eventually lead to history states being
pushed in the browser. This changes the location of the browser tab.
These distinct URLs are important for building the illusion of
"surfing": You can now navigate back and forth through the browser
history, create a bookmark or send a link to your best friend.

While serving static assets [is simple](/simple-fileserving/README.md),
serving the bootstrap file can be a bit tricky. Image you started
your SPA at path `/` and have clicked a few times. Your browser
location is now `/app/dashboard`. What happens if you reload? The
browser will request `/app/dahshboard` and expects the same bootstrap
HTML document to be served.

Therefore, we need to serve that file for _all possible SPA paths_.

Couper is designed with the specific challenges of SPAs in mind.
Let's see how the configuration would look like.

## Configuration

```hcl
server "spa" {
    files {
        document_root = "htdocs"
    }

    spa {
        bootstrap_file = "htdocs/index.html"
        paths = [ "/app/**" ]
    }
}
```

You have learned how to use the `files` section in the [file serving
example](/simple-fileserving/README.md).

The `spa` block is new. It is responsible for serving the bootstrap
document for all paths that match the `paths` list. Paths are matched
verbatim. However, you can use the `catch-all` operator `/**` here to
indicate that a path should match _including all sub paths_.

Note that the `bootstrap_file` lies within the `htdocs` directory.
This is not mandatory. We could read it from outside the document
root, if - for example - `/` should serve a static home page.

## Precedence

Couper checks each request against its configured handlers in this order:

* Matching endpoints (`api`)
* Matching files or directories (`files`)
* Matching SPA paths (`spa`)

Physical files will always win over the SPA bootstrap file.

Nevertheless, it is advisable to choose a distinct base path for your
SPA paths, such as `/app`, in order to reduce conflicts with asset
paths.

If you configure your `spa` paths onto `/**` (and `files` is usually
mounted on `/`, too), you will have the undesirable "only-200"
behavior.

## File not found

If you check the log output of Couper or your browser's network
inspector, you may see a `404` for `/favicon.ico`. Why is that
a good thing?

A naive approach to SPA serving is sending out the bootstrap document
for every file that is not found. That would _almost_ work like
intended. The SPA could initialize under all paths. But this would
effectively remove all `404`s from your logs. Why is that a bad thing?

First of all, a `404` responses for non-navigational requests (e.g.
CSS or image requests) are not processed by browsers. But more
importantly, a `404` is an information: Couper tells you - the
developer - that you might have made a mistake. With only `200`s in
the log, you wouldn't notice that you app bundle was renamed, that
the logo is missing and so on.
