function initializeFileTrees() {
  const fileTrees = document.querySelectorAll('.docyard-filetree');

  fileTrees.forEach(tree => {
    const folders = tree.querySelectorAll('.docyard-filetree__item--folder');

    folders.forEach(folder => {
      const entry = folder.querySelector(':scope > .docyard-filetree__entry');
      const childList = folder.querySelector(':scope > .docyard-filetree__list');

      if (!entry || !childList || childList.children.length === 0) return;

      folder.classList.add('docyard-filetree__item--has-children');

      entry.addEventListener('click', () => {
        const isCollapsed = folder.classList.contains('docyard-filetree__item--collapsed');

        folder.classList.toggle('docyard-filetree__item--collapsed');

        const icon = entry.querySelector('i[class*="ph-"]');
        if (icon) {
          if (isCollapsed) {
            icon.classList.remove('ph-folder');
            icon.classList.add('ph-folder-open');
          } else {
            icon.classList.remove('ph-folder-open');
            icon.classList.add('ph-folder');
          }
        }
      });
    });
  });
}

if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', initializeFileTrees);
} else {
  initializeFileTrees();
}
