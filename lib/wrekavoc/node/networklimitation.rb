require 'wrekavoc'

module Wrekavoc
  module Node

    class NetworkLimitation
      def self.apply(limitations)
        #case limitation.algorithm
        #  when Limitation::Network::Algorithm::TBF
        if limitations.is_a?(Limitation::Network::Rule)
          apply_tbf(limitations)
        else
          raise unless limitations.is_a?(Array)
          limitations.each { |limit| apply_tbf(limit) }
        end
        #  when Limitation::Network::Algorithm::HTB
        #    apply_htb(limitation)
        #  else
        #    apply_tbf(limitation)
        #end
      end

      def self.apply_tbf(limitation)
        iface = Lib::NetTools::get_iface_name(limitation.vnode,limitation.viface)
        baseiface = iface

        case limitation.direction
          when Limitation::Network::Direction::OUTPUT
            tcroot = TCWrapper::QdiscRoot.new(iface)
            tmproot = tcroot
          when Limitation::Network::Direction::INPUT
            tcroot = TCWrapper::QdiscIngress.new(iface)
            Lib::Shell.run(tcroot.get_cmd(TCWrapper::Action::ADD))
            iface = "ifb#{limitation.viface.id}"
            tmproot = TCWrapper::QdiscRoot.new(iface)
          else
            raise "Invalid direction"
        end


        primroot = nil
        bwlim = limitation.get_property(\
          Limitation::Network::Property::Type::BANDWIDTH)
        if bwlim
          tmproot = TCWrapper::QdiscTBF.new(iface,tmproot, \
              { 'rate' => "#{bwlim.rate}", 'buffer' => 1800, \
                'latency' => '50ms'})
          primroot = tmproot unless primroot
          Lib::Shell.run(tmproot.get_cmd(TCWrapper::Action::ADD))
        end

        latlim = limitation.get_property(\
          Limitation::Network::Property::Type::LATENCY)
        if latlim
          tmproot = TCWrapper::QdiscNetem.new(iface,tmproot, \
            {'delay' => "#{latlim.delay}"})
          primroot = tmproot unless primroot
          Lib::Shell.run(tmproot.get_cmd(TCWrapper::Action::ADD))
        end

        if limitation.direction == Limitation::Network::Direction::INPUT
          filter = TCWrapper::FilterU32.new(baseiface,tcroot,primroot)
          filter.add_match_u32('0','0')
          filter.add_param("action","mirred egress")
          filter.add_param("redirect","dev #{iface}")
          Lib::Shell.run(filter.get_cmd(TCWrapper::Action::ADD))
        end

      end

      def self.apply_htb(limitation)
      end
    end

  end
end