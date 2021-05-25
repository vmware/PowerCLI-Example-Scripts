// **************************************************************************
//  Copyright 2020 VMware, Inc.
// **************************************************************************
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace VMware.vSphere.SsoAdminClient.DataTypes
{
    public class Group
    {
        SsoAdminClient _client;
        public Group(SsoAdminClient client)
        {
            _client = client;
        }

        public string Name { get; set; }
        public string Domain { get; set; }
        public string Description { get; set; }

        public SsoAdminClient GetClient()
        {
            return _client;
        }

        public override string ToString()
        {
            return $"{Name}@{Domain}";
        }
    }
}
