export const SITE_NAME = 'DS with X';

// TODO: set once the GitHub repository exists (owner and name not yet chosen).
export const REPO_URL = 'https://github.com/OWNER/dswithx';
export const BRANCH = 'main';

export const githubUrl = (repoPath: string) => `${REPO_URL}/blob/${BRANCH}/${repoPath}`;
