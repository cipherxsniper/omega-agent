import { createClientFromRequest } from 'npm:@base44/sdk@0.8.40';

Deno.serve(async (req) => {
  try {
    const base44 = createClientFromRequest(req);
    const user = await base44.auth.me();
    if (!user) return Response.json({ error: 'Unauthorized' }, { status: 401 });

    const body = await req.json();
    const { action, repo_url, pat_token, branch, files } = body;

    if (!repo_url || !pat_token) {
      return Response.json({ error: 'repo_url and pat_token are required' }, { status: 400 });
    }

    // Parse owner and repo from URL
    const match = repo_url.match(/github\.com[/:]([^/]+)\/([^/.]+)/);
    if (!match) {
      return Response.json({ error: 'Invalid GitHub repository URL' }, { status: 400 });
    }
    const owner = match[1];
    const repo = match[2];
    const ref = branch || 'main';
    const headers = {
      'Authorization': `Bearer ${pat_token}`,
      'Accept': 'application/vnd.github+json',
      'Content-Type': 'application/json',
      'X-GitHub-Api-Version': '2022-11-28',
      'User-Agent': 'Omega-Super-Agent'
    };

    // Helper: safely parse JSON from a Response, falling back to text
    const safeJson = async (res) => {
      const text = await res.text();
      try { return JSON.parse(text); } catch { return { message: text }; }
    };

    if (action === 'push') {
      if (!files || !Array.isArray(files) || files.length === 0) {
        return Response.json({ error: 'files array is required for push' }, { status: 400 });
      }

      // Get the current branch ref (might not exist for empty repos)
      let latestCommitSha = null;
      let baseTreeSha = null;
      const refRes = await fetch(`https://api.github.com/repos/${owner}/${repo}/git/refs/heads/${ref}`, { headers });
      if (refRes.ok) {
        const refData = await safeJson(refRes);
        latestCommitSha = refData.object.sha;
        const commitRes = await fetch(`https://api.github.com/repos/${owner}/${repo}/git/commits/${latestCommitSha}`, { headers });
        if (commitRes.ok) {
          const commitData = await safeJson(commitRes);
          baseTreeSha = commitData.tree.sha;
        }
      }

      // Create blobs for each file
      const treeItems = [];
      for (const file of files) {
        const blobRes = await fetch(`https://api.github.com/repos/${owner}/${repo}/git/blobs`, {
          method: 'POST',
          headers,
          body: JSON.stringify({ content: file.content, encoding: 'utf-8' })
        });
        if (!blobRes.ok) {
          const err = await safeJson(blobRes);
          return Response.json({ error: `Failed to create blob for ${file.path}: ${err.message}` }, { status: 400 });
        }
        const blobData = await safeJson(blobRes);
        treeItems.push({
          path: file.path,
          mode: '100644',
          type: 'blob',
          sha: blobData.sha
        });
      }

      // Create tree
      const treeBody = { tree: treeItems };
      if (baseTreeSha) treeBody.base_tree = baseTreeSha;
      const treeRes = await fetch(`https://api.github.com/repos/${owner}/${repo}/git/trees`, {
        method: 'POST',
        headers,
        body: JSON.stringify(treeBody)
      });
      if (!treeRes.ok) {
        const err = await safeJson(treeRes);
        return Response.json({ error: `Failed to create tree: ${err.message}` }, { status: 400 });
      }
      const treeData = await safeJson(treeRes);

      // Create commit
      const commitBody = {
        message: `Omega sync: push ${files.length} files`,
        tree: treeData.sha,
      };
      if (latestCommitSha) commitBody.parents = [latestCommitSha];
      const commitCreateRes = await fetch(`https://api.github.com/repos/${owner}/${repo}/git/commits`, {
        method: 'POST',
        headers,
        body: JSON.stringify(commitBody)
      });
      if (!commitCreateRes.ok) {
        const err = await safeJson(commitCreateRes);
        return Response.json({ error: `Failed to create commit: ${err.message}` }, { status: 400 });
      }
      const newCommit = await safeJson(commitCreateRes);

      // Update or create ref
      if (latestCommitSha) {
        const updateRefRes = await fetch(`https://api.github.com/repos/${owner}/${repo}/git/refs/heads/${ref}`, {
          method: 'PATCH',
          headers,
          body: JSON.stringify({ sha: newCommit.sha })
        });
        if (!updateRefRes.ok) {
          const err = await safeJson(updateRefRes);
          return Response.json({ error: `Failed to update branch: ${err.message}` }, { status: 400 });
        }
      } else {
        const createRefRes = await fetch(`https://api.github.com/repos/${owner}/${repo}/git/refs`, {
          method: 'POST',
          headers,
          body: JSON.stringify({ ref: `refs/heads/${ref}`, sha: newCommit.sha })
        });
        if (!createRefRes.ok) {
          const err = await safeJson(createRefRes);
          return Response.json({ error: `Failed to create branch: ${err.message}` }, { status: 400 });
        }
      }

      return Response.json({
        status: 'success',
        commit_sha: newCommit.sha,
        commit_url: newCommit.html_url,
        files_pushed: files.length
      });
    }

    if (action === 'pull') {
      const treeRes = await fetch(`https://api.github.com/repos/${owner}/${repo}/git/trees/${ref}?recursive=1`, { headers });
      if (!treeRes.ok) {
        const err = await safeJson(treeRes);
        return Response.json({ error: `Failed to get tree: ${err.message}` }, { status: 400 });
      }
      const treeData = await safeJson(treeRes);
      const fileList = treeData.tree
        .filter(item => item.type === 'blob')
        .map(item => ({ path: item.path, sha: item.sha, size: item.size }));

      return Response.json({
        status: 'success',
        files: fileList,
        total: fileList.length
      });
    }

    return Response.json({ error: 'Unknown action. Use push or pull.' }, { status: 400 });
  } catch (error) {
    return Response.json({ error: error.message }, { status: 500 });
  }
});