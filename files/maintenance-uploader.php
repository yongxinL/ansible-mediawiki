<?php
/**
 * This is part of Lifamily Library (Wiki) project 
 * 
 * Copyright (C) 2010-2021     George Li <yongxinl@outlook.com>
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 * 
 * Upload one or more images from the local file system into the wiki without
 * using the web-based interface.
 * 
 * "Smart import" additions:
 * - aim: preserve the essential metadata (user, description) when importing media
 *   files from an existing wiki.
 * - process:
 *      - interface with the source wiki, don't use bare files only (see --source-wiki-url).
 *      - fetch metadata from source wiki for each file to import.
 *      - commit the fetched metadata to the destination wiki while submitting.
 *

 * *
 * @author George Li <yongxinL@outlook.com>
 * @version 1.0.0
 * @updated 2021.10.21
 */

require_once __DIR__ . '/Maintenance.php';

use MediaWiki\MediaWikiServices;

class Uploader extends Maintenance
{

	public function __construct()
	{
		parent::__construct();

		$this->addDescription('Imports images and other media files into the wiki');
		$this->addArg('dir', 'Path to the directory containing images to be imported');

		$this->addOption(
			'extensions',
			'Comma-separated list of allowable extensions, defaults to $wgFileExtensions',
			false,
			true
		);
		$this->addOption(
			'overwrite',
			'Overwrite existing images with the same name (default is to skip them)'
		);
		$this->addOption(
			'limit',
			'Limit the number of images to process. Ignored or skipped images are not counted',
			false,
			true
		);
		$this->addOption(
			'from',
			"Ignore all files until the one with the given name. Useful for resuming aborted "
				. "imports. The name should be the file's canonical database form.",
			false,
			true
		);
		$this->addOption(
			'skip-dupes',
			'Skip images that were already uploaded under a different name (check SHA1)'
		);
		$this->addOption('search-recursively', 'Search recursively for files in subdirectories');
		$this->addOption(
			'sleep',
			'Sleep between files. Useful mostly for debugging',
			false,
			true
		);
		$this->addOption(
			'user',
			"Set username of uploader, default 'Maintenance script'",
			false,
			true
		);
		// This parameter can optionally have an argument. If none specified, getOption()
		// returns 1 which is precisely what we need.
		$this->addOption('check-userblock', 'Check if the user got blocked during import');
		$this->addOption(
			'comment',
			"Set file description, default 'Importing file'",
			false,
			true
		);
		$this->addOption(
			'comment-file',
			'Set description to the content of this file',
			false,
			true
		);
		$this->addOption(
			'comment-ext',
			'Causes the description for each file to be loaded from a file with the same name, but '
				. 'the extension provided. If a global description is also given, it is appended.',
			false,
			true
		);
		$this->addOption(
			'summary',
			'Upload summary, description will be used if not provided',
			false,
			true
		);
		$this->addOption(
			'license',
			'Use an optional license template',
			false,
			true
		);
		$this->addOption(
			'timestamp',
			'Override upload time/date, all MediaWiki timestamp formats are accepted',
			false,
			true
		);
		$this->addOption(
			'protect',
			'Specify the protect value (autoconfirmed,sysop)',
			false,
			true
		);
		$this->addOption('unprotect', 'Unprotects all uploaded images');
		$this->addOption(
			'source-wiki-url',
			'If specified, take User and Comment data for each imported file from this URL. '
				. 'For example, --source-wiki-url="http://en.wikipedia.org/',
			false,
			true
		);
		$this->addOption(
			'category-start-from',
			'If specified, the category will start enumeration from there, not start from beginning, default A. '
				. 'For example, --category-start-from="Architecture',
			false,
			true
		);
		$this->addOption(
			'category-end-to',
			'If specified, the category will end enumeration from there, default ZZZ.',
			false,
			true
		);
		$this->addOption('dry', "Dry run, don't import anything");
	}

	public function execute()
	{
		global $wgFileExtensions, $wgUser, $wgRestrictionLevels;

		$permissionManager = MediaWikiServices::getInstance()->getPermissionManager();

		$processed = $added = $ignored = $skipped = $overwritten = $failed = 0;

		$this->output("Importing Files\n\n");

		$dir = $this->getArg(0);

		# Check Protection
		if ($this->hasOption('protect') && $this->hasOption('unprotect')) {
			$this->fatalError("Cannot specify both protect and unprotect.  Only 1 is allowed.\n");
		}

		if ($this->hasOption('protect') && trim($this->getOption('protect'))) {
			$this->fatalError("You must specify a protection option.\n");
		}

		# Prepare the list of allowed extensions
		$extensions = $this->hasOption('extensions')
			? explode(',', strtolower($this->getOption('extensions')))
			: $wgFileExtensions;

		# Search the path provided for candidates for import
		$files = $this->findFiles($dir, $extensions, $this->hasOption('search-recursively'));

		# Initialise the user for this operation
		$user = $this->hasOption('user')
			? User::newFromName($this->getOption('user'))
			: User::newSystemUser('Maintenance script', ['steal' => true]);
		if (!$user instanceof User) {
			$user = User::newSystemUser('Maintenance script', ['steal' => true]);
		}
		$wgUser = $user;

		# Get block check. If a value is given, this specified how often the check is performed
		$checkUserBlock = (int)$this->getOption('check-userblock');

		$from = $this->getOption('from');
		$sleep = (int)$this->getOption('sleep');
		$limit = (int)$this->getOption('limit');
		$timestamp = $this->getOption('timestamp', false);

		# Get the upload comment. Provide a default one in case there's no comment given.
		$commentFile = $this->getOption('comment-file');
		if ($commentFile !== null) {
			$comment = file_get_contents($commentFile);
			if ($comment === false || $comment === null) {
				$this->fatalError("failed to read comment file: {$commentFile}\n");
			}
		} else {
			$comment = $this->getOption('comment', 'Importing file');
		}
		$commentExt = $this->getOption('comment-ext');
		$summary = $this->getOption('summary', '');

		$license = $this->getOption('license', '');

		$sourceWikiUrl = $this->getOption('source-wiki-url');
		$categoryStart = $this->getOption('category-start-from', 'A');
		$categoryEnd   = $this->getOption('category-end-to', 'ZZZZZZ');

		# Initialise the category for this operation
		$category = $this->getCategoryFromSourceWiki($sourceWikiUrl, $categoryStart, $categoryEnd);

		# Batch "upload" operation
		$count = count($files);
		if ($count > 0) {
			$lbFactory = MediaWikiServices::getInstance()->getDBLoadBalancerFactory();
			foreach ($files as $file) {
				if ($sleep && ($processed > 0)) {
					sleep($sleep);
				}

				$base = UtfNormal\Validator::cleanUp(wfBaseName($file));
				$strbase = (strlen($base) > 70) ? substr($base, 0, 37) . '...' . substr($base, strlen($base)-30, 30) : $base;
				$strFile = (strlen($file) > 70) ? substr($file, 0, 37) . '...' . substr($file, strlen($file)-30, 30) : $file;

				# Validate a title
				$title = Title::makeTitleSafe(NS_FILE, $base);
				if (!is_object($title)) {
					$this->output(
						"{$strbase} could not be imported; a valid title cannot be produced\n"
					);
					continue;
				}

				if ($from) {
					if ($from == $title->getDBkey()) {
						$from = null;
					} else {
						$ignored++;
						continue;
					}
				}

				if ($checkUserBlock && (($processed % $checkUserBlock) == 0)) {
					$user->clearInstanceCache('name'); // reload from DB!
					if ($permissionManager->isBlockedFrom($user, $title)) {
						$this->output(
							"{$user->getName()} is blocked from {$title->getPrefixedText()}! skipping.\n"
						);
						$skipped++;
						continue;
					}
				}

				# Check existence
				$image = MediaWikiServices::getInstance()->getRepoGroup()->getLocalRepo()
					->newFile($title);
				if ($image->exists()) {
					if ($this->hasOption('overwrite')) {
						$this->output("{$strbase} exists, overwriting...");
						$svar = 'overwritten';
					} else {
						$this->output("Importing {$strbase} exists, skipping\n");
						$skipped++;
						continue;
					}
				} else {
					if ($this->hasOption('skip-dupes')) {
						$repo = $image->getRepo();
						# XXX: we end up calculating this again when actually uploading. that sucks.
						$sha1 = FSFile::getSha1Base36FromPath($file);

						$dupes = $repo->findBySha1($sha1);

						if ($dupes) {
							$this->output(
								"{$strbase} already exists as {$dupes[0]->getName()}, skipping\n"
							);
							$skipped++;
							continue;
						}
					}

					$this->output("Importing {$strbase}...");
					$svar = 'added';
				}

				if ($sourceWikiUrl) {
					/* find comment text directly from source wiki, through MW's API */
					$real_comment = $this->getFileCommentFromSourceWiki($sourceWikiUrl, $base);
					if ($real_comment === false) {
						$commentText = $comment;
					} else {
						$commentText = $real_comment;
					}

					/* find user directly from source wiki, through MW's API */
					$real_user = $this->getFileUserFromSourceWiki($sourceWikiUrl, $base);
					if ($real_user === false) {
						$wgUser = $user;
					} else {
						$wgUser = User::newFromName($real_user);
						if ($wgUser === false) {
							# user does not exist in target wiki
							$this->output(
								"\n failed: user '$real_user' does not exist in target wiki."
							);
							continue;
						}
					}
				} else {
					# Find comment text
					$commentText = false;

					if ($commentExt) {
						$f = $this->findAuxFile($file, $commentExt);
						if (!$f) {
							$this->output("\n No comment file with extension {$commentExt} found "
								. "for {$file}, using default comment. ");
						} else {
							$commentText = file_get_contents($f);
							if (!$commentText) {
								$this->output(
									"\n Failed to load comment file {$f}, using default comment. "
								);
							}
						}
					}
				}

				// further analyzing and get comment from file
				if (!$commentText) {
					$commentText = $this->getFileCommentFromFile($sourceWikiUrl, $file, $category);
				}

				# Import the file
				if ($this->hasOption('dry')) {
					$this->output(
						"\n publishing {$strFile} by '{$wgUser->getName()}',\n comment '$commentText'... "
					);
				} else {
					$mwProps = new MWFileProps(MediaWiki\MediaWikiServices::getInstance()->getMimeAnalyzer());
					$props = $mwProps->getPropsFromPath($file, true);
					$flags = 0;
					$publishOptions = [];
					$handler = MediaHandler::getHandler($props['mime']);
					if ($handler) {
						$metadata = \Wikimedia\AtEase\AtEase::quietCall('unserialize', $props['metadata']);

						$publishOptions['headers'] = $handler->getContentHeaders($metadata);
					} else {
						$publishOptions['headers'] = [];
					}
					$archive = $image->publish($file, $flags, $publishOptions);
					if (!$archive->isGood()) {
						$this->output("\nfailed. (" .
							$archive->getMessage(false, false, 'en')->text() .
							")\n");
						$failed++;
						continue;
					}
				}

				$commentText = SpecialUpload::getInitialPageText($commentText, $license);
				if (!$this->hasOption('summary')) {
					$summary = $commentText;
				}

				if ($this->hasOption('dry')) {
					$this->output(" done.\n");
				} elseif ($image->recordUpload2(
					$archive->value,
					$summary,
					$commentText,
					$props,
					$timestamp
				)->isOK()) {
					$this->output("done.\n");

					$doProtect = false;

					$protectLevel = $this->getOption('protect');

					if ($protectLevel && in_array($protectLevel, $wgRestrictionLevels)) {
						$doProtect = true;
					}
					if ($this->hasOption('unprotect')) {
						$protectLevel = '';
						$doProtect = true;
					}

					if ($doProtect) {
						# Protect the file
						$this->output("\nWaiting for replica DBs...\n");
						// Wait for replica DBs.
						sleep(2); # Why this sleep?
						$lbFactory->waitForReplication();

						$this->output("\nSetting image restrictions ... ");

						$cascade = false;
						$restrictions = [];
						foreach ($title->getRestrictionTypes() as $type) {
							$restrictions[$type] = $protectLevel;
						}

						$page = WikiPage::factory($title);
						$status = $page->doUpdateRestrictions($restrictions, [], $cascade, '', $user);
						$this->output(($status->isOK() ? 'done' : 'failed') . "\n");
					}
				} else {
					$this->output("failed. (at recordUpload stage)\n");
					$svar = 'failed';
				}

				$$svar++;
				$processed++;

				if ($limit && $processed >= $limit) {
					break;
				}
			}

			# Print out some statistics
			$this->output("\n");
			foreach ([
					'count' => 'Found',
					'limit' => 'Limit',
					'ignored' => 'Ignored',
					'added' => 'Added',
					'skipped' => 'Skipped',
					'overwritten' => 'Overwritten',
					'failed' => 'Failed'
				] as $var => $desc) {
				if ($$var > 0) {
					$this->output("{$desc}: {$$var}\n");
				}
			}
		} else {
			$this->output("No suitable files could be found for import.\n");
		}
	}

	/**
	 * Search a directory for files with one of a set of extensions
	 *
	 * @param string $dir Path to directory to search
	 * @param array $exts Array of extensions to search for
	 * @param bool $recurse Search subdirectories recursively
	 * @return array|bool Array of filenames on success, or false on failure
	 */
	private function findFiles($dir, $exts, $recurse = false)
	{
		if (is_dir($dir)) {
			$dhl = opendir($dir);
			if ($dhl) {
				$files = [];
				while (($file = readdir($dhl)) !== false) {
					if (is_file($dir . '/' . $file)) {
						$ext = pathinfo($file, PATHINFO_EXTENSION);
						if (array_search(strtolower($ext), $exts) !== false) {
							$files[] = $dir . '/' . $file;
						}
					} elseif ($recurse && is_dir($dir . '/' . $file) && $file !== '..' && $file !== '.') {
						$files = array_merge($files, $this->findFiles($dir . '/' . $file, $exts, true));
					}
				}

				return $files;
			} else {
				return [];
			}
		} else {
			return [];
		}
	}

	/**
	 * Find an auxilliary file with the given extension, matching
	 * the give base file path. $maxStrip determines how many extensions
	 * may be stripped from the original file name before appending the
	 * new extension. For example, with $maxStrip = 1 (the default),
	 * file files acme.foo.bar.txt and acme.foo.txt would be auxilliary
	 * files for acme.foo.bar and the extension ".txt". With $maxStrip = 2,
	 * acme.txt would also be acceptable.
	 *
	 * @param string $file Base path
	 * @param string $auxExtension The extension to be appended to the base path
	 * @param int $maxStrip The maximum number of extensions to strip from the base path (default: 1)
	 * @return string|bool
	 */
	private function findAuxFile($file, $auxExtension, $maxStrip = 1)
	{
		if (strpos($auxExtension, '.') !== 0) {
			$auxExtension = '.' . $auxExtension;
		}

		$d = dirname($file);
		$n = basename($file);

		while ($maxStrip >= 0) {
			$f = $d . '/' . $n . $auxExtension;

			if (file_exists($f)) {
				return $f;
			}

			$idx = strrpos($n, '.');
			if (!$idx) {
				break;
			}

			$n = substr($n, 0, $idx);
			$maxStrip -= 1;
		}

		return false;
	}

	/**
	 * @todo FIXME: Access the api in a saner way and performing just one query
	 * (preferably batching files too).
	 *
	 * @param string $wiki_host
	 * @param string $file
	 *
	 * @return string|bool
	 */
	private function getFileCommentFromSourceWiki($wiki_host, $file)
	{
		$url = $wiki_host . '/api.php?action=query&format=xml&titles=File:'
			. rawurlencode($file) . '&prop=imageinfo&&iiprop=comment';
		$body = Http::get($url, [], __METHOD__);
		if (preg_match('#<ii comment="([^"]*)" />#', $body, $matches) == 0) {
			return false;
		}

		return html_entity_decode($matches[1]);
	}

	private function getFileUserFromSourceWiki($wiki_host, $file)
	{
		$url = $wiki_host . '/api.php?action=query&format=xml&titles=File:'
			. rawurlencode($file) . '&prop=imageinfo&&iiprop=user';
		$body = Http::get($url, [], __METHOD__);
		if (preg_match('#<ii user="([^"]*)" />#', $body, $matches) == 0) {
			return false;
		}

		return html_entity_decode($matches[1]);
	}

	/**
	 * Read Category from Wiki and return as array.
	 *
	 * @param string $wiki_host  
	 * @param string $cat_start
	 * @param string $cat_end
	 * @return array
	 */
	private function getCategoryFromSourceWiki($wiki_host, $cat_start, $cat_end)
	{
		$category = [];
		$params = [
			"action" 	=> "query",
			"format"	=> "json",
			"aclimit"	=> 500,
			"list"		=> "allcategories",
			"acfrom"	=> $cat_start,
			"acto"		=> $cat_end
		];
		$url = rtrim($wiki_host, '/') . '/w/api.php?' . http_build_query($params);
		$body = json_decode(Http::get($url, [], __METHOD__), true);

		// build category array
		foreach ($body["query"]["allcategories"] as $k => $v) {
			if (strpos($v["*"], '/') !== false) {
				$category[explode('/', $v["*"])[0]][] = explode( '/', preg_replace( '/[^A-Za-z0-9 \-]\s/', '', $v["*"] ));
			}
		}

		return $category;
	}

	/**
	 * Check title if subpage exists
	 *
	 * @param string $wiki_host  
	 * @param string $page
	 * @return bool
	 */
	private function getSubpageFromSourceWiki($wiki_host, $page)
	{
		$params = [
			"action" 	=> "query",
			"format"	=> "xml",
			"titles"	=> $page
		];
		$url = rtrim($wiki_host, '/') . '/w/api.php?' . http_build_query($params);
		$body = Http::get($url, [], __METHOD__);
		if (preg_match('/missing=/', $body) == 0) {
			return true;
		}
		return false;
	}

	/**
	 * return Category and extra information from file.
	 *
	 * @param string $wiki_host  
	 * @param string $file  
	 * @param array $category
	 * @return string
	 */
	private function getFileCommentFromFile($wiki_host, $file, $category)
	{
		$base = explode('-', UtfNormal\Validator::cleanUp(wfBaseName($file)));
		$positionStart = 0;
		$wordExclude = array("and", "or");
		$wordLetterMatch = 5;
		$categoryLevelMatch = 3;
		$categoryFound = [];
		$comment = '';
		
		// build category from timestamp
		if (preg_match('/^[0-9]{8}$/', $base[0]) and date('Y', strtotime($base[0])) > 1970) {
			$comment .= '[[Category:' . date('Y/Y0m', strtotime($base[0])) . ']]';
			$positionStart++;
		} elseif (preg_match('/^[0-9]*$/', $base[0])) {
			$comment .= '[[Category:' . date('Y/Y0m', strtotime('now')) . ']]';
			$positionStart++;
		} else {
			$comment .= '[[Category:' . date('Y/Y0m', strtotime('now')) . ']]';
		}

		// build category from filename
		if (isset( $base[$positionStart] )) {
			foreach( $category as $key => $subcat ) {
				// separate category into word and match.
				foreach( explode( ' ', $key ) as $word ) {
					if( in_array( $word, $wordExclude ) || in_array( $base[$positionStart], $wordExclude )){
						continue;
					} elseif ( preg_match( '/^' . substr( $base[$positionStart], 0, $wordLetterMatch) . '/i', $word )
							|| strtolower( $base[$positionStart] ) == strtolower( $word ) ){
						$categoryFound[0] = $key;
						break;
					}
				}
			}
		}
		if ( isset( $categoryFound[0] ) && count($base) - $positionStart > 0 ) {
			// shrink $category
			$category = $category[$categoryFound[0]];
			// initialize $categoryFound[1] for avoiding error on $categoryFound[$i-1]
			$categoryFound[1] = '';

			foreach( $category as $subcat ) {
				for( $i = 1; $i <= $categoryLevelMatch; $i++ ) {
					// check if previous of $categoryFound and $subcat is match, also current $subcat is set
					if ( isset( $subcat[$i] ) && ( $subcat[$i-1] == $categoryFound[$i-1] )) {
						//separate subcategory into word and match
						foreach( explode( ' ', $subcat[$i] ) as $word ) {
							if( in_array( $word, $wordExclude ) || in_array( $base[$i + $positionStart], $wordExclude )){
								continue;
							} elseif ( preg_match( '/^' . substr( $base[$i + $positionStart], 0, $wordLetterMatch) . '/i', $word )) {
								$categoryFound[$i] = $subcat[$i];
								break;
							}
						}
					} else { break;	}
				}
			}
			if ( empty( $categoryFound[1]) ) unset( $categoryFound[1] );
		}
		if ( count($categoryFound) > 0 ) {
			$positionStart = $positionStart + count($categoryFound);
			$comment .= '[[Category:' . str_replace(' ', '_', implode( '/', $categoryFound )) . ']]';
		}

		/**
		 * add page/subpage title based on file
		 *
		 * text in P[$positionStart] will be added to comment regardless of whether pagetitle exists.
		 * text in P[$positionStart + 1] will be added when title[0]/title[1] exists.
		 * text in P[$positionStart + 2] will be added when title[0]/title[1]/title[2]subpage exists.
		 * 
		 */

		if ( isset( $base[$positionStart] ) && !preg_match('/^\d/', $base[$positionStart] )) {
			$comment .= '[[';

			if ( isset( $base[$positionStart + 2] )
				&& $this->getSubpageFromSourceWiki( $wiki_host, $this->reformat( $base[$positionStart] )
				. '/' . $this->reformat( $base[$positionStart + 1] ) . '/' . $this->reformat( $base[$positionStart + 2] ))
			) {
				$comment .= $this->reformat( $base[$positionStart] ) 
				. '/' . $this->reformat( $base[$positionStart + 1] )
				. '/' . $this->reformat( $base[$positionStart + 2]);
			} elseif (isset( $base[$positionStart + 1] )
				&& $this->getSubpageFromSourceWiki($wiki_host, $this->reformat( $base[$positionStart] )
				. '/' . $this->reformat( $base[$positionStart + 1] ))) {
				$comment .= $this->reformat( $base[$positionStart + 1])
				. '/' . $this->reformat( $base[$positionStart + 2] );
			} else {
				$comment .= $this->reformat( $base[$positionStart] );
			}

			$comment .= ']]';
		}

		return $comment;
	}

	/**
	 * format text to improve readability
	 * Notes:
	 * - regex 1: '\W+' will repace adjacent special characters to a space.
	 * - regex 2: (?<!\) will to prevent add space before a capital letter that already ahs a space before it.
	 * - regex 3: (?<=[a-z])(?=[A-Z]) will match every position where immediately precedes is a lowercase letter,
	 *                              the replacement is a single space, which will insert a space at these positions.
	 *
	 * @param string $file  
	 * @return string
	 */
	private function reformat($page)
	{
		$page = preg_replace('/\W+/', ' ', $page);						// see regex 1
		$page = preg_replace('/(?<=[a-z])(?=[A-Z])/', ' ', $page);		// see regex 3
		$page = ucwords($page);											// uppercase the first character of each word
		$page = str_replace(' ', '_', $page);								// replace space with '_'
		return $page;
	}
}

$maintClass = Uploader::class;
require_once RUN_MAINTENANCE_IF_MAIN;