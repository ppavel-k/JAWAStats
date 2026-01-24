document.addEventListener('DOMContentLoaded', function() {
    const colElems = document.querySelectorAll('.collapsible');
    const colInstances = M.Collapsible.init(colElems, {
        accordion: false
    });

    const sideElems = document.querySelectorAll('.sidenav');
    const sideInstances = M.Sidenav.init(sideElems, {
    });
  });

