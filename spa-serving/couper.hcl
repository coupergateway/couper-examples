server "spa" {
    // file server mounted on /, existing files take precedence
    files {
        document_root = "htdocs"
    }

    // serve bootstrap file
    spa {
        bootstrap_file = "htdocs/index.html"
        // under these paths and their sub directories
        paths = [ "/app/**", "/help/**" ]
    }
}
