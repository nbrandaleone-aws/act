# act
Appmesh Configuration Terminal. A tool to help with AWS App Mesh set-up and configuration.

In order to configure AWS App Mesh, you must detail at least 5 levels of information.  This can be make it challenging to view all the relevant info, especially from the Console. This tool aims to make this a simpler process.

It is loosly based upon [kubectl-tree](https://ahmet.im/blog/kubectl-tree/).

![Image of working tool](/images/act.png)

This is a prototype, and not yet fully functioning.  However, I am happy to take pull requests and recommendation/suggestions.  I have a roadmap, for my own work stated below.

### Information needed for App Mesh
1. Mesh name
2. Virtual Service (inbound DNS name)
3. Virtual Router or Virtual Node
4. One or more Routes
5. Virtual Nodes (listener information)
6. Virtual Node info (i.e. Backends and logging)

### Roadmap
- [x] Initial Commit for prototype
- [ ] Add "list" toggle. In progress.
- [ ] Get working with Virtual Routers/Routes
- [ ] Add create/edit functionality
- [ ] ? Turn into a Terminal UI ?
- [ ] Rewrite in more portable or popular language (Rust, Go, JS, Python) ?
