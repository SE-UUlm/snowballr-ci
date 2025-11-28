/**
 * Script to replace GitHub URLs pointing to a source branch with a specified target branch name
 * in all wiki files and the README.md file.
 *
 * Usage: node scripts/wiki-replace-github-urls.js <owner/repo> <source-branch> <target-branch>
 */

import fs from "fs/promises";
import path from "path";

// Parse command line arguments
const args = process.argv.slice(2);
if (args.length !== 5) {
    console.error(
        "Error: Please provide a repository (owner/repo), a source branch, a target branch, the README path, and the wiki directory path as arguments"
    );
    console.error(
        "Usage: node wiki-replace-github-urls.js <owner/repo> <source-branch> <target-branch> <readme-path> <wiki-dir>"
    );
    process.exit(1);
}

// Normalize repository argument (allow optional .git suffix)
const repo = args[0].replace(/\.git$/i, "");
const sourceBranch = args[1];
const targetBranch = args[2];
const readmePath = args[3];
const wikiPath = args[4];
console.log(
    `Replacing GitHub URLs for "${repo}" from "${sourceBranch}" to "${targetBranch}"...`
);
console.log(`README Path: ${readmePath}`);
console.log(`Wiki Directory: ${wikiPath}`);

/**
 * Recursively get all files in a directory.
 *
 * @param {string} dirPath - Directory path
 * @param {Array} fileList - List to append files to
 * @returns {Promise<Array>} - List of file paths
 */
async function getAllFiles(dirPath, fileList = []) {
    const items = await fs.readdir(dirPath, { withFileTypes: true });

    for (const item of items) {
        const fullPath = path.join(dirPath, item.name);

        if (item.isDirectory()) {
            // Recursively process subdirectories
            await getAllFiles(fullPath, fileList);
        } else if (
            item.isFile() &&
            (item.name.endsWith(".md") ||
                item.name.endsWith(".mdx") ||
                item.name.endsWith(".markdown"))
        ) {
            // Only include markdown files
            fileList.push(fullPath);
        }
    }

    return fileList;
}

/**
 * Replace GitHub URLs in a file.
 *
 * @param {string} filePath - Path to the file
 * @returns {Promise<boolean>} - True if file was updated, false otherwise
 */
async function processFile(filePath) {
    try {
        // Read file content
        const content = await fs.readFile(filePath, "utf-8");

        // Escape repo and branch strings for RegExp
        const escapeForRegExp = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
        const repoEscaped = escapeForRegExp(repo);
        const sourceBranchEscaped = escapeForRegExp(sourceBranch);

        // Replace GitHub Blob URLs
        const blobRegex = new RegExp(
            `https://github\\.com/${repoEscaped}/blob/${sourceBranchEscaped}/`,
            "g"
        );
        let updatedContent = content.replace(
            blobRegex,
            `https://github.com/${repo}/blob/${targetBranch}/`
        );

        // Replace GitHub Tree URLs
        const treeRegex = new RegExp(
            `https://github\\.com/${repoEscaped}/tree/${sourceBranchEscaped}/`,
            "g"
        );
        updatedContent = updatedContent.replace(
            treeRegex,
            `https://github.com/${repo}/tree/${targetBranch}/`
        );

        // If content was updated, write it back to file
        if (content !== updatedContent) {
            await fs.writeFile(filePath, updatedContent, "utf-8");
            console.log(`Updated: ${filePath}`);
            return true;
        }

        return false;
    } catch (error) {
        console.error(`Error processing file ${filePath}:`, error.message);
        return false;
    }
}

/**
 * Main function
 */
async function main() {
    try {
        let wikiFiles = [];
        try {
            const stat = await fs.stat(wikiPath);
            if (stat.isDirectory()) {
                wikiFiles = await getAllFiles(wikiPath);
            } else {
                console.warn(
                    `Wiki path is not a directory: ${wikiPath}. Skipping wiki files.`
                );
            }
        } catch (err) {
            console.warn(
                `Wiki path not found: ${wikiPath}. Skipping wiki files.`
            );
        }

        let filesToProcess = [];
        try {
            const statReadme = await fs.stat(readmePath);
            if (statReadme.isFile()) {
                filesToProcess = [...wikiFiles, readmePath];
            } else {
                console.warn(
                    `README path is not a file: ${readmePath}. Skipping README.`
                );
                filesToProcess = [...wikiFiles];
            }
        } catch (err) {
            console.warn(`README not found: ${readmePath}. Skipping README.`);
            filesToProcess = [...wikiFiles];
        }

        // Process all files
        let updatedCount = 0;
        for (const file of filesToProcess) {
            const wasUpdated = await processFile(file);
            if (wasUpdated) updatedCount++;
        }

        // Log results
        console.log(
            `\nProcessed ${filesToProcess.length} file(s), updated ${updatedCount} file(s).`
        );

        if (updatedCount > 0) {
            console.log("GitHub URLs have been successfully replaced.");
        } else {
            console.log("No GitHub URLs were found to replace.");
        }
    } catch (error) {
        console.error("Error:", error.message);
        process.exit(1);
    }
}

// Run the script
main();
