# frozen_string_literal: true

# name: discourse-s3-path-style
# about: Bring back S3 path-style
# version: 0.0.1
# authors: Jiajun Du
# url: https://github.com/ShuiyuanSJTU/discourse-s3-path-style
# required_version: 2.7.0

enabled_site_setting :plugin_s3_path_style

after_initialize do
    $mylogger = Logger.new("log/test.log")
    module OverrideAbsoluteUrl
        def absolute_base_url
            url_basename = SiteSetting.s3_endpoint.split('/')[-1]
            bucket = SiteSetting.enable_s3_uploads ? Discourse.store.s3_bucket_name : GlobalSetting.s3_bucket_name
            # cf. http://docs.aws.amazon.com/general/latest/gr/rande.html#s3_region
            if SiteSetting.s3_endpoint.blank? || SiteSetting.s3_endpoint.end_with?("amazonaws.com")
              if SiteSetting.Upload.s3_region.start_with?("cn-")
                "//#{bucket}.s3.#{SiteSetting.Upload.s3_region}.amazonaws.com.cn"
              else
                "//#{bucket}.s3.dualstack.#{SiteSetting.Upload.s3_region}.amazonaws.com"
              end
            else
              if SiteSetting.plugin_s3_path_style
                "//#{url_basename}/#{bucket}"
              else
                "//#{bucket}.#{url_basename}"
              end
            end
        end
    end

    module OverrideS3Config
        def s3_options(obj)
            opts = {
              region: obj.s3_region,
              force_path_style: SiteSetting.plugin_s3_path_style
            }
        
            opts[:endpoint] = SiteSetting.s3_endpoint if SiteSetting.s3_endpoint.present?
            opts[:http_continue_timeout] = SiteSetting.s3_http_continue_timeout
        
            unless obj.s3_use_iam_profile
              opts[:access_key_id] = obj.s3_access_key_id
              opts[:secret_access_key] = obj.s3_secret_access_key
            end
        
            opts
        end
    end

    SiteSetting::Upload.singleton_class.prepend OverrideAbsoluteUrl
    S3Helper.singleton_class.prepend OverrideS3Config

end
