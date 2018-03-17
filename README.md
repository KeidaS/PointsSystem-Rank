# PointsSystem-Rank

Ranking based on points.

Users can win points with the command !givepoint <name> . Points can be revoked using the command !removepoint <name>.  

For watch the rank use !points.

For using this plugin you need to add this to your databses.cfg file (the file is located in \csgo\addons\sourcemod\configs\databases.cfg):

```
"rankme"
	{
		"driver"			"mysql"
		"host"				"YOUR HOST"
		"database"			"rank" (you can put what you want)
		"user"				"YOUR USER"
		"pass"				"YOUR PASSWORD"
	}
  ```
