#/bin/sh

user="$1"
password="$2"

if [ -z "$user" ]; then
  printf "GitHub username: "
  read user
else
  echo "Using GitHub username $user."
fi

archive_name="github-archive-$user-`date +%Y-%m-%d`"
archive_dir="$archive_name"
archive_file="${archive_name}.tar.gz"

if [ -d "$archive_dir" ]; then
  echo "Archive directory already exists, exiting: $archive_dir."
  exit 1
fi

if [ -z "$password" ]; then
  printf "GitHub password (enter nothing for public repos only): "
  stty -echo
  read password
  echo
  stty echo
else
  echo "Using GitHub password from arguments."
fi

if [ -z "$password" ]; then
  echo "\nGathering public repo list only."
  url="https://api.github.com/users/$user/repos?type=owner"
else
  echo "\nGathering public and private repo list."
  url="https://api.github.com/user/repos?type=owner"
fi

# TODO: Handle HTTP 401 Unauthorized responses.

while [ -n "$url" ]; do
  echo "Reading from $url."
  if [ -z "$password" ]; then
    response=`curl -s -i "$url"`
  else
    response=`echo -u "${user}:${password}" | curl -s -i -K - "$url"`
  fi
  url=`echo "$response" | grep -e "^Link:.*rel=\"next\"" | sed 's/^.*\(https:\/\/.*\)>.*rel=\"next\".*$/\1/'`
  page_repos=`echo "$response" | grep -e "\"ssh_url\":" | awk -F\" '{ print $4 }'`
  repos="$repos\n$page_repos"
done

repos=`echo "$repos" | sed '/^[ \t]*$/d'`
if [ -z "$repos" ]; then
  echo "No repos found."
  exit 1
fi

total=`echo "$repos" | wc -l | awk '{ print $1 }'`

echo "\nRepos to be cloned ($total):"
echo "$repos\n"

echo "Cloning repos into $archive_dir.\n"
mkdir "$archive_dir"
cd "$archive_dir"

# TODO: Handle clone failures.

count=1
for repo in `echo "$repos"`; do
  echo "Cloning $repo ($count of $total)."
  git clone "$repo"
  echo
  count=$(($count + 1))
done

echo "Creating archive."
cd - >/dev/null
tar zcf "$archive_file" "$archive_dir"

echo "Archive written to $archive_file.\nFin."
