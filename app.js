(() => {
  const STORAGE_KEY = 'scanrun.tasks.v1';

  const state = {
    tasks: [],
    filters: {
      status: 'all',
      priority: 'all',
      search: ''
    }
  };

  const storage = {
    load() {
      try {
        const raw = localStorage.getItem(STORAGE_KEY);
        return raw ? JSON.parse(raw) : [];
      } catch {
        return [];
      }
    },
    save(tasks) {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(tasks));
    }
  };

  const dom = {
    form: document.getElementById('task-form'),
    title: document.getElementById('task-title'),
    description: document.getElementById('task-description'),
    priority: document.getElementById('task-priority'),
    status: document.getElementById('task-status'),
    list: document.getElementById('task-list'),
    filterStatus: document.getElementById('filter-status'),
    filterPriority: document.getElementById('filter-priority'),
    search: document.getElementById('search'),
    stats: document.getElementById('stats'),
    clearCompleted: document.getElementById('clear-completed'),
    taskTemplate: document.getElementById('task-template')
  };

  const helpers = {
    id() {
      return crypto.randomUUID();
    },
    nowIso() {
      return new Date().toISOString();
    },
    normalize(text) {
      return (text || '').trim().toLowerCase();
    }
  };

  const selectors = {
    filteredTasks() {
      return state.tasks.filter(task => {
        const matchesStatus =
          state.filters.status === 'all' || task.status === state.filters.status;
        const matchesPriority =
          state.filters.priority === 'all' || task.priority === state.filters.priority;
        const query = helpers.normalize(state.filters.search);
        const textBlob = helpers.normalize(`${task.title} ${task.description}`);
        const matchesSearch = !query || textBlob.includes(query);
        return matchesStatus && matchesPriority && matchesSearch;
      });
    },
    counts() {
      const total = state.tasks.length;
      const done = state.tasks.filter(task => task.status === 'done').length;
      const inProgress = state.tasks.filter(task => task.status === 'in-progress').length;
      const backlog = state.tasks.filter(task => task.status === 'backlog').length;
      return { total, done, inProgress, backlog };
    }
  };

  const actions = {
    addTask(input) {
      state.tasks.unshift({
        id: helpers.id(),
        title: input.title.trim(),
        description: input.description.trim(),
        priority: input.priority,
        status: input.status,
        createdAt: helpers.nowIso(),
        updatedAt: helpers.nowIso()
      });
      actions.persistAndRender();
    },

    updateTask(id, patch) {
      state.tasks = state.tasks.map(task => {
        if (task.id !== id) return task;
        return {
          ...task,
          ...patch,
          updatedAt: helpers.nowIso()
        };
      });
      actions.persistAndRender();
    },

    deleteTask(id) {
      state.tasks = state.tasks.filter(task => task.id !== id);
      actions.persistAndRender();
    },

    clearCompleted() {
      state.tasks = state.tasks.filter(task => task.status !== 'done');
      actions.persistAndRender();
    },

    persistAndRender() {
      storage.save(state.tasks);
      ui.render();
    }
  };

  const ui = {
    render() {
      ui.renderList();
      ui.renderStats();
    },

    renderList() {
      dom.list.innerHTML = '';
      const tasks = selectors.filteredTasks();

      if (!tasks.length) {
        const empty = document.createElement('li');
        empty.className = 'task-item';
        empty.textContent = 'No tasks match your current filters.';
        dom.list.appendChild(empty);
        return;
      }

      tasks.forEach(task => {
        const fragment = dom.taskTemplate.content.cloneNode(true);
        const item = fragment.querySelector('.task-item');
        const title = fragment.querySelector('.task-title');
        const description = fragment.querySelector('.task-description');
        const priority = fragment.querySelector('.task-priority');
        const statusSelect = fragment.querySelector('.task-status-select');
        const editBtn = fragment.querySelector('.edit-btn');
        const deleteBtn = fragment.querySelector('.delete-btn');

        item.dataset.id = task.id;
        title.textContent = task.title;
        description.textContent = task.description || 'No description provided.';
        priority.textContent = task.priority;
        priority.classList.add(task.priority);
        statusSelect.value = task.status;

        statusSelect.addEventListener('change', event => {
          actions.updateTask(task.id, { status: event.target.value });
        });

        editBtn.addEventListener('click', () => {
          const nextTitle = prompt('Update title', task.title);
          if (nextTitle === null) return;
          const nextDescription = prompt('Update description', task.description);
          if (nextDescription === null) return;
          actions.updateTask(task.id, {
            title: nextTitle.trim() || task.title,
            description: nextDescription.trim()
          });
        });

        deleteBtn.addEventListener('click', () => {
          actions.deleteTask(task.id);
        });

        dom.list.appendChild(fragment);
      });
    },

    renderStats() {
      const { total, backlog, inProgress, done } = selectors.counts();
      dom.stats.textContent = `Total: ${total} • Backlog: ${backlog} • In Progress: ${inProgress} • Done: ${done}`;
    }
  };

  const events = {
    bind() {
      dom.form.addEventListener('submit', event => {
        event.preventDefault();
        actions.addTask({
          title: dom.title.value,
          description: dom.description.value,
          priority: dom.priority.value,
          status: dom.status.value
        });
        dom.form.reset();
        dom.priority.value = 'medium';
        dom.status.value = 'backlog';
      });

      dom.filterStatus.addEventListener('change', () => {
        state.filters.status = dom.filterStatus.value;
        ui.render();
      });

      dom.filterPriority.addEventListener('change', () => {
        state.filters.priority = dom.filterPriority.value;
        ui.render();
      });

      dom.search.addEventListener('input', () => {
        state.filters.search = dom.search.value;
        ui.render();
      });

      dom.clearCompleted.addEventListener('click', () => {
        actions.clearCompleted();
      });
    }
  };

  function boot() {
    state.tasks = storage.load();
    events.bind();
    ui.render();
  }

  boot();
})();
