# Simple File-Serving

Every Web Application begins with a client (browser) loading an HTML
page. All necessary scripts, styles and images are referenced in the HTML document and in turn requested by the browser. The rest is browsing history :)

The counterpart to the Web client is the good, old Web server that serves static files on the clients demand.

Let's do that with couper!


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
