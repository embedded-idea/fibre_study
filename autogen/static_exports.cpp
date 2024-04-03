
#include <fibre/func_utils.hpp>
#include <fibre/object_server.hpp>
#include "interfaces.hpp"

using namespace fibre;

const Function* fibre::static_server_function_table[] = {
    &SyncMemberWrapper<decltype(&fibre::Property<const uint32_t>::read), &fibre::Property<const uint32_t>::read>::instance,
    &SyncMemberWrapper<decltype(&fibre::Property<uint32_t>::exchange), &fibre::Property<uint32_t>::exchange>::instance,
    &SyncMemberWrapper<decltype(&fibre::Property<uint32_t>::read), &fibre::Property<uint32_t>::read>::instance,
    &SyncMemberWrapper<decltype(&TestIntf1_SubobjIntf::subfunc), &TestIntf1_SubobjIntf::subfunc>::instance,
    &SyncMemberWrapper<decltype(&TestIntf1Intf::func00), &TestIntf1Intf::func00>::instance,
    &SyncMemberWrapper<decltype(&TestIntf1Intf::func01), &TestIntf1Intf::func01>::instance,
    &SyncMemberWrapper<decltype(&TestIntf1Intf::func02), &TestIntf1Intf::func02>::instance,
    &SyncMemberWrapper<decltype(&TestIntf1Intf::func10), &TestIntf1Intf::func10>::instance,
    &SyncMemberWrapper<decltype(&TestIntf1Intf::func11), &TestIntf1Intf::func11>::instance,
    &SyncMemberWrapper<decltype(&TestIntf1Intf::func12), &TestIntf1Intf::func12>::instance,
    &SyncMemberWrapper<decltype(&TestIntf1Intf::func20), &TestIntf1Intf::func20>::instance,
    &SyncMemberWrapper<decltype(&TestIntf1Intf::func21), &TestIntf1Intf::func21>::instance,
    &SyncMemberWrapper<decltype(&TestIntf1Intf::func22), &TestIntf1Intf::func22>::instance,
};

template<> ServerInterfaceId fibre::get_interface_id<TestIntf1Intf>() { return 0; };
template<> ServerInterfaceId fibre::get_interface_id<fibre::Property<const uint32_t>>() { return 1; };
template<> ServerInterfaceId fibre::get_interface_id<fibre::Property<uint32_t>>() { return 2; };
template<> ServerInterfaceId fibre::get_interface_id<TestIntf1_SubobjIntf>() { return 3; };

// Must be defined by the application
extern TestIntf1Intf* test_object_ptr;

ServerObjectDefinition fibre::static_server_object_table[] = {
    make_obj(test_object_ptr),
    make_obj(test_object_ptr->get_prop_uint32()),
    make_obj(test_object_ptr->get_prop_uint32_rw()),
    make_obj(test_object_ptr->get_subobj()),
};

size_t fibre::n_static_server_functions = 13;
size_t fibre::n_static_server_objects = 4;