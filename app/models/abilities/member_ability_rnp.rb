# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2012 Mconf
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

module Abilities

  class MemberAbilityRNP < MemberAbility

    alias :super_register :register_abilities
    def register_abilities(user)
      super_register(user)

      # Institutions
      can [:select], Institution
    end

  end

end