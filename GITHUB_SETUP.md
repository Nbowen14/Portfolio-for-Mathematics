# Publish the portfolio on GitHub

This package already contains the complete portfolio, improved app.R, report,
and code viewer. No website build or command-line Git setup is required.

## 1. Extract the download

On Windows, right-click `GitHub_Portfolio_Package.zip`, choose **Extract All**,
and open the extracted `differentiability-portfolio` folder.

You should see `index.html`, `app.R`, `README.md`, and the `assets`, `files`,
`tests`, and `tools` folders.

Upload the contents of that folder. Do not upload the ZIP itself or place the
whole containing folder inside another repository folder. `index.html` must be
at the top level of the repository for the Pages settings below.

## 2. Create the repository

1. Sign in at https://github.com.
2. Open https://github.com/new.
3. For **Repository name**, enter `differentiability-portfolio`.
4. Optional description: `Project 3: an R Shiny differentiability explorer, modeling report, and portfolio website.`
5. For free GitHub Pages hosting, choose **Public**. This makes the code and
   report visible to anyone. Private-repository Pages hosting requires an
   eligible paid GitHub plan.
6. Leave the README, license, and ignore-file initialization options off; this
   package supplies its own project files.
7. Click **Create repository**.

## 3. Upload the project

1. On the empty repository page, click **uploading an existing file**. If the
   repository already contains a file, choose **Add file → Upload files**.
2. Open the extracted project folder in File Explorer.
3. Select its contents and drag them onto the GitHub upload page. Include the
   folders, not only the individual files at the top level.
4. Check that `index.html` appears directly in the repository, with `assets`
   and `files` alongside it.
5. Enter a commit message, such as `Add differentiability portfolio and Shiny app`.
6. Click **Commit changes**. Use the default branch, normally `main`.

## 4. Enable the portfolio website

1. Open the repository's **Settings** tab.
2. Select **Pages** in the left sidebar.
3. Under **Build and deployment → Source**, choose **Deploy from a branch**.
4. Select the branch containing your uploaded files, normally **main**.
5. For the folder, select **/(root)**.
6. Click **Save**.
7. Wait for the Pages deployment to finish. Return to **Settings → Pages**
   and open the published website link. The **Actions** tab shows deployment
   progress and any errors.

For this repository name, the usual website address is:

`https://YOUR-USERNAME.github.io/differentiability-portfolio/`

Replace `YOUR-USERNAME` with your actual GitHub username. Use the exact URL
shown by GitHub Pages once deployment succeeds.

## 5. Check the finished page

- Change the illustrated function and move the point slider.
- Open or download the full PDF.
- Use the code tabs and **Full app.R**.
- Download the R source.
- Check the page on a phone or with a narrow browser window.

Share the website link for the portfolio and the repository link for the source.
They are different links. The full Shiny app still runs in RStudio; GitHub Pages
serves the portfolio and downloadable project files.

## Official instructions

- GitHub Pages: https://docs.github.com/en/pages/getting-started-with-github-pages/what-is-github-pages
- Upload files: https://docs.github.com/en/repositories/working-with-files/managing-files/adding-a-file-to-a-repository
- Configure Pages: https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site
