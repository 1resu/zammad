# Copyright (C) 2012-2014 Zammad Foundation, http://zammad-foundation.org/

class Translation < ApplicationModel
  before_create :set_initial
  after_create  :cache_clear
  after_update  :cache_clear
  after_destroy :cache_clear

=begin

load translations from online

all:

  Translation.load

dedicated:

  Translation.load(locale) # e. g. en-us or de-de

=end

  def self.load(dedicated_locale = nil)
    locales_list = []
    if !dedicated_locale
      locales = Locale.to_sync
      locales.each {|locale|
        locales_list.push locale.locale
      }
    else
      locales_list = [dedicated_locale]
    end
    locales_list.each {|locale|
      url = "https://i18n.zammad.com/api/v1/translations/#{locale}"
      if !UserInfo.current_user_id
        UserInfo.current_user_id = 1
      end
      result = UserAgent.get(
        url,
        {},
        {
          json: true,
        }
      )
      fail "Can't load translations from #{url}: #{result.error}" if !result.success?

      ActiveRecord::Base.transaction do
        result.data.each {|translation_raw|

          # handle case insensitive sql
          exists      = Translation.where(locale: translation_raw['locale'], format: translation_raw['format'], source: translation_raw['source'])
          translation = nil
          exists.each {|item|
            if item.source == translation_raw['source']
              translation = item
            end
          }
          if translation

            # verify if update is needed
            update_needed = false
            translation_raw.each {|key, _value|
              if translation_raw[key] == translation[key]
                update_needed = true
                break
              end
            }
            if update_needed
              translation.update_attributes(translation_raw.symbolize_keys!)
              translation.save
            end
          else
            Translation.create(translation_raw.symbolize_keys!)
          end
        }
      end
    }
    true
  end

=begin

push translations to online

  Translation.push(locale)

=end

  def self.push(locale)

    # only push changed translations
    translations         = Translation.where(locale: locale)
    translations_to_push = []
    translations.each {|translation|
      if translation.target != translation.target_initial
        translations_to_push.push translation
      end
    }

    return true if translations_to_push.empty?

    url = 'https://i18n.zammad.com/api/v1/thanks_for_your_support'

    translator_key = Setting.get('translator_key')

    result = UserAgent.post(
      url,
      {
        locale: locale,
        translations: translations_to_push,
        fqdn: Setting.get('fqdn'),
        translator_key: translator_key,
      },
      {
        json: true,
      }
    )
    fail "Can't push translations to #{url}: #{result.error}" if !result.success?

    # set new translator_key if given
    if result.data['translator_key']
      translator_key = Setting.set('translator_key', result.data['translator_key'])
    end

    true
  end

=begin

reset translations to origin

  Translation.reset(locale)

=end

  def self.reset(locale)

    # only push changed translations
    translations = Translation.where(locale: locale)
    translations.each {|translation|
      if !translation.target_initial || translation.target_initial.empty?
        translation.destroy
      elsif translation.target != translation.target_initial
        translation.target = translation.target_initial
        translation.save
      end
    }

    true
  end

=begin

get list of translations

  list = Translation.list('de-de')

=end

  def self.list(locale, admin = false)

    # use cache if not admin page is requested
    if !admin
      data = cache_get(locale)
    end
    if !data

      # show total translations as reference count
      data = {
        'total' => Translation.where(locale: 'de-de').count,
      }
      list = []
      translations = Translation.where(locale: locale.downcase).order(:source)
      translations.each { |item|
        if admin
          translation_item = [
            item.id,
            item.source,
            item.target,
            item.target_initial,
            item.format,
          ]
          list.push translation_item
        else
          translation_item = [
            item.id,
            item.source,
            item.target,
            item.format,
          ]
          list.push translation_item
        end
        data['list'] = list
      }

      # set cache
      if !admin
        cache_set(locale, data)
      end
    end

    data
  end

=begin

translate strings in ruby context, e. g. for notifications

  translated = Translation.translate('de-de', 'New')

=end

  def self.translate(locale, string)

    # translate string
    records = Translation.where( locale: locale, source: string )
    records.each {|record|
      return record.target if record.source == string
    }

    # fallback lookup in en
    records = Translation.where( locale: 'en', source: string )
    records.each {|record|
      return record.target if record.source == string
    }

    string
  end

  private

  def set_initial

    return if target_initial
    self.target_initial = target
  end

  def cache_clear
    Cache.delete( 'TranslationMap::' + locale.downcase )
  end

  def self.cache_set(locale, data)
    Cache.write( 'TranslationMap::' + locale.downcase, data )
  end

  def self.cache_get(locale)
    Cache.get( 'TranslationMap::' + locale.downcase )
  end
end
