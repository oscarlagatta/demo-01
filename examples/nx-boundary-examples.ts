// Example of Nx module boundary enforcement

// libs/shared/ui/project.json
{
  \
  "tags\": [\"scope:shared\", \"type:ui\"]
}

// libs/feature/user-profile/project.json
{
  ;("tags")
  : ["scope:feature", "type:feature"]
}
