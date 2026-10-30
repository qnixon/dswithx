export const SITE_NAME = 'DS with X';

// Until launch, ask search engines not to index the site. Set to true at launch.
export const LAUNCHED = false;

// Languages listed first, in this order, everywhere languages appear (tabs,
// coverage grid, language index); the rest follow alphabetically.
export const LANGUAGES_FIRST = ['python'];

export const REPO_URL = 'https://github.com/qnixon/dswithx';
export const BRANCH = 'main';

export const githubUrl = (repoPath: string) => `${REPO_URL}/blob/${BRANCH}/${repoPath}`;
