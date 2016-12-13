# coding: utf-8
# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

module RnpHelper

  def requirements_url
    # "https://wiki.rnp.br/pages/viewpage.action?pageId=89112372#ManualdoUsuáriodoserviçodeconferênciaweb-Requisitosdeuso"
    check_bigbluebutton_server_url(BigbluebuttonServer.default)
  end

  def service_page_url
    "https://www.rnp.br/servicos/servicos-avancados/conferencia-web"
  end

  def mconf_tec_url
    "http://mconf.com"
  end

  def compatibility_url
    "https://wiki.rnp.br/pages/viewpage.action?pageId=90402465"
  end

  def sidenav_for_user?
    params[:controller] == "my"
  end

  def sidenav_for_spaces?
    @space.present?
  end

  def sidenav_room
    if sidenav_for_user?
      current_user.try(:bigbluebutton_room)
    else
      @space.try(:bigbluebutton_room)
    end
  end
end
