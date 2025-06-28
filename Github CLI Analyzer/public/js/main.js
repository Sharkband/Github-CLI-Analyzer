fetchRateLimit()
let repoChartInstance = null;
let commitsChartInstance = null;

async function fetchRepos() {
  
  const username = document.getElementById('username').value;
  const res = await fetch(`/api/repos/${username}`);
  fetchRateLimit()
  const data = await res.json();
  const output = document.getElementById('repositorys');
  
  output.innerHTML = '<h2>Repositories:</h2>';
  

  if (res.ok) {
    const repoNames = [];
    const stars = [];
    
    data.forEach(repo => {
      repoNames.push(repo.name)
      stars.push(repo.Stars)

      output.innerHTML += `<p><strong><a href="${repo.url}" target="_blank">${repo.name}</a></strong>: ${repo.description || 'No description'}</p>`;
      output.innerHTML += `<ul><li>Open Issues: ${repo.OpenIssues}</li><li>Forks: ${repo.forks}</li><li>Stars: ${repo.Stars}</li><li>Watchers: ${repo.Watchers}</li><li>Language: ${repo.Language || 'None'}</li></ul>`
      
    });

    //destroying chart if it exists
    if (repoChartInstance !== null) {
      repoChartInstance.destroy();
    }
    output.innerHTML += `<canvas id="repoChart" width="400" height="200"></canvas>`
    const ctx = document.getElementById('repoChart').getContext('2d');
    repoChartInstance = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: repoNames,
        datasets: [{
          label: 'Stars per Repository',
          data: stars,
          backgroundColor: 'rgba(19, 87, 22, 0.6)',
          borderColor: 'rgba(19, 87, 22, 0.6)',
          borderWidth: 1
        }]
      },
      options: {
        scales: {
          y: { beginAtZero: true }
        }
      }
    });

  } else {
    output.innerHTML = `<p style="color:red;">Error: ${data.error}</p>`;
  }
}

async function fetchButtons() {
  const username = document.getElementById('username').value;
  const res = await fetch(`/api/repos/${username}`);
  fetchRateLimit()
  const data = await res.json();
  const output = document.getElementById('commits');
  output.innerHTML = '<h2>Commit History:</h2>';

  if (res.ok) {
    
    data.forEach(repo => {
      output.innerHTML += `<button onclick="fetchCommits('${repo.name}')">${repo.name}</button><br>`;
      
    });
  } else {
    output.innerHTML = `<p style="color:red;">Error: ${data.error}</p>`;
  }
}

async function fetchCommits(repo) {
  const username = document.getElementById('username').value;
  //const repo = prompt("Enter repository name:");
  const res = await fetch(`/api/commits/${username}/${repo}`);
  fetchRateLimit()
  const data = await res.json();
  const output = document.getElementById('commits');

  const resActivity = await fetch(`/api/commit-activity/${username}/${repo}`);
  const stats = await resActivity.json();

  if (!Array.isArray(stats)) {
    const message = stats.message || stats.error || "Unexpected response from server.";
    alert(`Could not load commit activity: ${message}`);
    return;
  }

  const labels = stats.map(d => d.week_start);
  const dataActivity = stats.map(d => d.total_commits);

  output.innerHTML = `<h2>Commits for ${repo}:</h2>`;

  if (res.ok) {
    data.forEach(commit => {
      output.innerHTML += `<p>${commit.message} — <em>${commit.author}</em></p>`;
    });
    output.innerHTML += `<button onclick="fetchButtons()">Back</button><br>`;

    output.innerHTML += `<canvas id="commitsChart" width="600" height="300"></canvas>`

    const ctx = document.getElementById('commitsChart').getContext('2d');

    // Destroy existing chart to avoid stacking
    if (commitsChartInstance) {
      commitsChartInstance.destroy();
    }

    commitsChartInstance = new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [{
          label: `Commits per Week – ${repo}`,
          data: dataActivity,
          fill: false,
          borderColor: 'rgba(19, 87, 22, 0.6)',
          tension: 0.3
        }]
      },
      options: {
        scales: {
          y: { beginAtZero: true }
        }
      }
    });
  } else {
    output.innerHTML = `<p style="color:red;">Error: ${data.error}</p>`;
  }
}

async function fetchProfile() {
  const username = document.getElementById('username').value;
  const res = await fetch(`/api/profile/${username}`);
  fetchRateLimit()
  const data = await res.json();
  const output = document.getElementById('profile');
  output.innerHTML = '<h2>Profile:</h2>';

  if (res.ok) {
    
    
      output.innerHTML += `
      <img src="${data.avatar_url}" alt="${data.login}" width="100" style="border-radius: 50%;" />
      <h2>${data.name || data.login}</h2>
      <p>${data.bio || ''}</p>
      <p>Followers: ${data.followers} | Following: ${data.following}</p>
      <p>Public repos: ${data.public_repos}</p>
      <p>Location: ${data.location || 'N/A'}</p>
      <p>Blog: ${data.blog ? `<a href="${data.blog}" target="_blank">${data.blog}</a>` : 'N/A'}</p>
      <a href="${data.html_url}" target="_blank">View GitHub Profile</a>
      <hr />
    `;
      
    
  } else {
    output.innerHTML = `<p style="color:red;">Error: ${data.error}</p>`;
  }
}

async function fetchAll() {
  await fetchProfile();  // fetch and display profile info
  await fetchRepos();    // fetch and display repos
  await fetchButtons();  // fetch and display commits
}


async function fetchRateLimit() {
  const res = await fetch(`/api/rate_limit`);
  const data = await res.json();
  const output = document.getElementById('rate-limit-label');
  output.innerHTML = `API calls left: ${data.remaining} / ${data.limit} (resets at ${data.reset_at})`;

}
