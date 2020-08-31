# Simple File-Serving

Every Web Application begins with a client (browser) loading an HTML
page. All necessary scripts, styles and images are referenced in the HTML document and in turn requested by the browser. The rest is browsing history :)

The counterpart to the Web client is the good, old Web server that serves static files on the clients' demand.

Let's do that with Couper!

## Configuration

The core configuration looks like this:

```hcl
server "file-server" {
  files {
    document_root = "htdocs"
  }
}
```

We define a `server` block and give it a name (`file-server`). The
`files` block configures Couper's file server. It needs to know which directory to serve (`document_root`).

That's all it takes!

## Custom Error File

If you have clicked on the ["Broken
link"](http://localhost:8080/brokenlink) in your browser, you saw the
built-in error page with our beloved Couper mascot.

You can define your own error document like this:

```hcl
server "file-server" {
  files {
    document_root = "htdocs"
    error_file = "error.html"
  }
}
```

All paths are resolved relativ to the config file. Notice that `error.html` is located outside of the `htdocs/` folder.

If you want to reference assets in your error file, keep in mind, that it is served from every thinkable path on your server. Therefore, all links should start with `/`, like in `<img src="/assets/couper-logo.svg">`.

The error file can contain placeholders for specific information about
the requested path, the HTTP status code and so on. We use [Go Template Syntax](https://golang.org/pkg/text/template/) for that. Check [`error.html`](error.html) for examples.
