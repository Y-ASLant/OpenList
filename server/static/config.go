package static

import (
	"strings"

	"github.com/OpenListTeam/OpenList/v4/internal/conf"
	"github.com/OpenListTeam/OpenList/v4/pkg/utils"
)

type SiteConfig struct {
	BasePath string
	Cdn      string
}

func getSiteConfig() SiteConfig {
	siteConfig := SiteConfig{
		BasePath: conf.URL.Path,
		Cdn:      strings.ReplaceAll(strings.TrimSuffix(conf.Conf.Cdn, "/"), "$version", strings.TrimPrefix(conf.WebVersion, "v")),
	}
	if siteConfig.BasePath != "" {
		siteConfig.BasePath = utils.FixAndCleanPath(siteConfig.BasePath)
		// Keep consistent with frontend: trim trailing slash unless it's root
		if siteConfig.BasePath != "/" && strings.HasSuffix(siteConfig.BasePath, "/") {
			siteConfig.BasePath = strings.TrimSuffix(siteConfig.BasePath, "/")
		}
	}
	if siteConfig.BasePath == "" {
		siteConfig.BasePath = "/"
	}
	// 优先使用 CDN：如果未配置，使用默认的国内镜像
	if siteConfig.Cdn == "" {
		// 默认使用 npmmirror 国内镜像加速静态资源
		version := strings.TrimPrefix(conf.WebVersion, "v")
		if version != "" && version != "dev" && version != "beta" && version != "rolling" {
			siteConfig.Cdn = "https://registry.npmmirror.com/openlist-web/" + version + "/files/dist"
			utils.Log.Infof("Using default CDN: %s", siteConfig.Cdn)
		} else {
			// 开发版本或未知版本，降级到本地路径
			siteConfig.Cdn = strings.TrimSuffix(siteConfig.BasePath, "/")
		}
	} else if strings.ToLower(siteConfig.Cdn) == "local" || strings.ToLower(siteConfig.Cdn) == "none" {
		// 用户明确设置为 local 或 none 时，强制使用本地加载
		utils.Log.Info("CDN disabled, using local static files")
		siteConfig.Cdn = ""
	}
	return siteConfig
}
