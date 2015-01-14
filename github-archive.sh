user="$1"

if [ -z "$user" ]; then
  echo "Specify username: $0 <username>"
  exit 1
fi

archive_name="github-archive-$user-`date +%Y-%m-%d`"
archive_dir="$archive_name"
archive_file="${archive_name}.tar.gz"

if [ -d "$archive_dir" ]; then
  echo "Archive directory already exists, exiting: $archive_dir."
  exit 1
fi

echo "Gathering repo list."

url="https://api.github.com/users/$user/repos?type=owner"
while [ -n "$url" ]; do
  echo "Reading from $url."
  response=`curl --silent -i "$url"`
  url=`echo "$response" | grep -e "^Link:.*rel=\"next\"" | sed 's/^.*\(https:\/\/.*\)>.*rel=\"next\".*$/\1/'`
  page_repos=`echo "$response" | grep -e "\"git_url\":" | awk -F\" '{ print $4 }'`
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

read -p "Create archive (y/n)? " response
if [[ ! $response =~ ^[Yy]$ ]]; then
  echo "Exiting."
  exit 1
fi

echo "\nCloning repos into $archive_dir."
mkdir "$archive_dir"
cd "$archive_dir"

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
